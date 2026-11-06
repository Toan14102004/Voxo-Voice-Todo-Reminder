//
//  CoreDataTodoRepository.swift
//  VoxoShared
//

import CoreData
import Foundation

public final class CoreDataTodoRepository: TodoRepository, SyncOutbox, ProcessedOpLog {
    private let container: NSPersistentContainer
    private let device: DeviceRole
    private let merger: MergeService

    /// One context for all writes, so "same transaction" in PLAN.md §6.1 is enforceable: a todo
    /// change and its `SyncOp` land in a single `save()`, or neither does.
    private var context: NSManagedObjectContext { container.viewContext }

    public init(stack: PersistenceStack, device: DeviceRole) {
        container = stack.container
        self.device = device
        merger = MergeService(device: device)
    }

    // MARK: - Reads

    public func activeTodos() throws -> [TodoDTO] {
        try fetchTodos(predicate: NSPredicate(format: "isDone == NO AND deletedAt == nil"), key: "createdAt")
    }

    public func completedTodos() throws -> [TodoDTO] {
        try fetchTodos(predicate: NSPredicate(format: "isDone == YES AND deletedAt == nil"), key: "completedAt")
    }

    public func todo(id: UUID) throws -> TodoDTO? {
        try entity(id: id)?.dto
    }

    // MARK: - Local mutations (these enqueue a SyncOp on the Watch)

    @discardableResult
    public func create(title: String, intervalOverride: Int32 = 0, now: Date) throws -> TodoDTO {
        guard let clean = TodoDTO.sanitize(title: title) else { throw RepositoryError.emptyTitle }

        let dto = TodoDTO(
            title: clean,
            createdAt: now,
            updatedAt: now,
            intervalOverride: intervalOverride,
            // A brand new todo is due as soon as one interval has passed; Phase 2's scheduler
            // takes it from here.
            nextRemindAt: nil,
            originDevice: device
        )

        try write(op: .create, todo: dto, now: now) { entity in
            entity.apply(dto)
        }
        return dto
    }

    public func update(_ todo: TodoDTO, now: Date) throws {
        guard let clean = TodoDTO.sanitize(title: todo.title) else { throw RepositoryError.emptyTitle }
        guard try entity(id: todo.id) != nil else { throw RepositoryError.notFound(todo.id) }

        var updated = todo
        updated.title = clean
        updated.updatedAt = now

        try write(op: .update, todo: updated, now: now) { entity in
            entity.apply(updated)
        }
    }

    public func complete(id: UUID, now: Date) throws {
        guard let existing = try entity(id: id) else { throw RepositoryError.notFound(id) }

        var updated = existing.dto
        updated.isDone = true
        updated.completedAt = now
        updated.updatedAt = now
        // Completing stops reminders for good (PLAN.md §1 rule 4).
        updated.nextRemindAt = nil

        try write(op: .complete, todo: updated, now: now) { entity in
            entity.apply(updated)
        }
    }

    public func delete(id: UUID, now: Date) throws {
        guard let existing = try entity(id: id) else { throw RepositoryError.notFound(id) }

        var updated = existing.dto
        updated.deletedAt = now
        updated.updatedAt = now
        updated.nextRemindAt = nil

        try write(op: .delete, todo: updated, now: now) { entity in
            entity.apply(updated)
        }
    }

    // MARK: - Remote application

    @discardableResult
    public func apply(remote: TodoDTO) throws -> TodoDTO? {
        let existing = try entity(id: remote.id)

        switch merger.merge(local: existing?.dto, incoming: remote) {
        case .keepLocal:
            return nil

        case let .insert(winner):
            let entity = TodoEntity(context: context)
            entity.apply(winner)
            try save()
            return winner

        case let .update(winner):
            guard let existing else { return nil }
            existing.apply(winner)
            try save()
            return winner
        }
    }

    @discardableResult
    public func purgeTombstones(olderThan maxAge: TimeInterval = MergeService.tombstoneRetention, now: Date) throws -> Int {
        let request = TodoEntity.fetchRequest()
        request.predicate = NSPredicate(format: "deletedAt != nil AND deletedAt <= %@", now.addingTimeInterval(-maxAge) as NSDate)

        let doomed = try context.fetch(request)
        doomed.forEach(context.delete)
        if !doomed.isEmpty { try save() }
        return doomed.count
    }

    // MARK: - SyncOutbox

    public func pendingOps() throws -> [SyncOpDTO] {
        let request = SyncOpEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        return try context.fetch(request).compactMap(\.dto)
    }

    public func pendingOpCount() throws -> Int {
        try context.count(for: SyncOpEntity.fetchRequest())
    }

    @discardableResult
    public func acknowledge(opIds: [UUID]) throws -> Int {
        guard !opIds.isEmpty else { return 0 }

        let request = SyncOpEntity.fetchRequest()
        request.predicate = NSPredicate(format: "opId IN %@", opIds)

        let acknowledged = try context.fetch(request)
        acknowledged.forEach(context.delete)
        if !acknowledged.isEmpty { try save() }
        return acknowledged.count
    }

    // MARK: - ProcessedOpLog

    @discardableResult
    public func markProcessed(opId: UUID, now: Date) throws -> Bool {
        if try hasProcessed(opId: opId) { return false }

        let entry = ProcessedOpEntity(context: context)
        entry.opId = opId
        entry.processedAt = now
        try save()
        return true
    }

    public func hasProcessed(opId: UUID) throws -> Bool {
        let request = ProcessedOpEntity.fetchRequest()
        request.predicate = NSPredicate(format: "opId == %@", opId as CVarArg)
        request.fetchLimit = 1
        return try context.count(for: request) > 0
    }

    // MARK: - Private

    private func entity(id: UUID) throws -> TodoEntity? {
        let request = TodoEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    private func fetchTodos(predicate: NSPredicate, key: String) throws -> [TodoDTO] {
        let request = TodoEntity.fetchRequest()
        request.predicate = predicate
        // `id` breaks ties: several todos can share a timestamp (a batch sync, or two taps in the
        // same second), and without it the list order shuffles between launches.
        request.sortDescriptors = [
            NSSortDescriptor(key: key, ascending: true),
            NSSortDescriptor(key: "id", ascending: true)
        ]
        return try context.fetch(request).map(\.dto)
    }

    /// Applies a local change and, on the Watch, its outbox entry — in one `save()`.
    private func write(op type: SyncOpType, todo: TodoDTO, now: Date, mutate: (TodoEntity) -> Void) throws {
        let entity = try self.entity(id: todo.id) ?? TodoEntity(context: context)
        mutate(entity)

        if device == .watch {
            let op = try SyncOpDTO(type: type, todo: todo, createdAt: now)
            let opEntity = SyncOpEntity(context: context)
            opEntity.apply(op)
        }

        try save()
    }

    private func save() throws {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            // Leaving a half-applied change in the context would break the "same transaction"
            // guarantee for the next write.
            context.rollback()
            throw error
        }
    }
}
