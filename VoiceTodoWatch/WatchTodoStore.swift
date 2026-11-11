//
//  WatchTodoStore.swift
//  VoiceTodoWatch
//

import Combine
import Foundation
import VoxoShared

/// Watch-side state.
///
/// The Watch works fully on its own (PLAN.md §8 Phase 4): every change is written locally and
/// queued in the outbox, whether or not the iPhone is reachable.
@MainActor
final class WatchTodoStore: ObservableObject {
    @Published private(set) var active: [TodoDTO] = []
    /// Today's finished work only. The design shows it under the open tasks; the full history
    /// belongs on the phone, and a watch list that grows forever is unusable.
    @Published private(set) var doneToday: [TodoDTO] = []
    @Published private(set) var lists: [TodoListDTO] = []
    @Published private(set) var pendingSyncCount: Int = 0
    @Published private(set) var lastError: String?

    private let repository: TodoRepository
    private let listRepository: TodoListRepository?
    private let outbox: SyncOutbox
    private var session: WatchSessionManager?

    init(repository: TodoRepository & SyncOutbox) {
        self.repository = repository
        listRepository = repository as? TodoListRepository
        outbox = repository
        reload()
    }

    func attach(session: WatchSessionManager) {
        self.session = session
    }

    func reload() {
        perform {
            // Ordered by time of day, as in the design: the repository sorts by createdAt, which
            // on a watch list reads as random.
            active = try repository.activeTodos().sorted { lhs, rhs in
                switch (lhs.dueAt, rhs.dueAt) {
                case let (left?, right?): left < right
                // A task with no time sits after the scheduled ones.
                case (nil, _?): false
                case (_?, nil): true
                default: lhs.createdAt < rhs.createdAt
                }
            }
            let startOfDay = Calendar.current.startOfDay(for: Date())
            doneToday = try repository.completedTodos()
                .filter { ($0.completedAt ?? .distantPast) >= startOfDay }
            lists = (try? listRepository?.lists()) ?? []
            pendingSyncCount = try outbox.pendingOpCount()
        }
    }

    /// Reads the published arrays first, so a detail screen re-renders when the record changes.
    func todo(id: UUID) -> TodoDTO? {
        active.first { $0.id == id }
            ?? doneToday.first { $0.id == id }
            ?? (try? repository.todo(id: id))
    }

    func list(id: UUID?) -> TodoListDTO? {
        guard let id else { return nil }
        return lists.first { $0.id == id }
    }

    func add(title: String) {
        perform {
            try repository.create(title: title, intervalOverride: 0, now: Date())
            reload()
            session?.flushOutbox()
        }
    }

    /// Saves what `TaskParser` made of a dictated sentence. Returns the stored todo so the
    /// confirmation screen can undo it.
    @discardableResult
    func add(parsed: ParsedTask) -> TodoDTO? {
        var stored: TodoDTO?
        perform {
            let now = Date()
            var created = try repository.create(title: parsed.title, intervalOverride: 0, now: now)
            if parsed.isStructured {
                created.dueAt = parsed.dueAt
                created.listId = parsed.listId
                created.priority = parsed.priority
                try repository.update(created, now: now)
            }
            stored = created
            reload()
            session?.flushOutbox()
        }
        return stored
    }

    /// A tombstone, not a hard delete, so the phone learns the task is gone (PLAN.md §6).
    func delete(_ todo: TodoDTO) {
        perform {
            try repository.delete(id: todo.id, now: Date())
            reload()
            session?.flushOutbox()
        }
    }

    func complete(_ todo: TodoDTO) {
        perform {
            try repository.complete(id: todo.id, now: Date())
            reload()
            session?.flushOutbox()
        }
    }

    /// Ticking the ring has to work both ways: the design keeps finished tasks on screen.
    func toggleDone(_ todo: TodoDTO) {
        todo.isDone ? reopen(todo) : complete(todo)
    }

    func reopen(_ todo: TodoDTO) {
        perform {
            try repository.reopen(id: todo.id, now: Date())
            reload()
            session?.flushOutbox()
        }
    }

    /// Writes a whole edited record. The outbox carries the full DTO, so changing a field on the
    /// watch reaches the phone the same way a rename does.
    func update(_ todo: TodoDTO) {
        perform {
            try repository.update(todo, now: Date())
            reload()
            session?.flushOutbox()
        }
    }

    func rename(_ todo: TodoDTO, to title: String) {
        perform {
            var updated = todo
            updated.title = title
            try repository.update(updated, now: Date())
            reload()
            session?.flushOutbox()
        }
    }

    private func perform(_ work: () throws -> Void) {
        do {
            try work()
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }
}
