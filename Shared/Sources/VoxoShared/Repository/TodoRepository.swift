//
//  TodoRepository.swift
//  VoxoShared
//

import Foundation

/// The only way into Core Data (PLAN.md §2) — views never touch `NSManagedObjectContext`.
///
/// Local mutations (`create`/`update`/`complete`/`delete`) enqueue a `SyncOp` on the Watch, in the
/// same transaction as the change (PLAN.md §6.1). Remote application (`apply`) never does, so an
/// incoming change cannot bounce back to its sender.
public protocol TodoRepository {
    func activeTodos() throws -> [TodoDTO]
    func completedTodos() throws -> [TodoDTO]
    func todo(id: UUID) throws -> TodoDTO?

    @discardableResult
    func create(title: String, intervalOverride: Int32, now: Date) throws -> TodoDTO
    func update(_ todo: TodoDTO, now: Date) throws
    func complete(id: UUID, now: Date) throws
    func delete(id: UUID, now: Date) throws

    /// Applies a change that arrived from the other device, after merging. Writes no `SyncOp`.
    /// Returns the todo as it stands after the merge, or nil when the incoming version lost.
    @discardableResult
    func apply(remote: TodoDTO) throws -> TodoDTO?

    /// Drops tombstones older than `maxAge` (PLAN.md §6: 30 days).
    @discardableResult
    func purgeTombstones(olderThan maxAge: TimeInterval, now: Date) throws -> Int
}

/// The Watch outbox from PLAN.md §6: ops survive until the phone acknowledges them.
public protocol SyncOutbox {
    func pendingOps() throws -> [SyncOpDTO]
    func pendingOpCount() throws -> Int
    /// Removes acknowledged ops. Unknown ids are ignored. Returns how many were actually removed.
    @discardableResult
    func acknowledge(opIds: [UUID]) throws -> Int
}

/// Phone-side dedupe ledger (PLAN.md §6.3).
public protocol ProcessedOpLog {
    /// Records the op and reports whether it is new. A repeat returns false and changes nothing.
    func markProcessed(opId: UUID, now: Date) throws -> Bool
    func hasProcessed(opId: UUID) throws -> Bool
}

public enum RepositoryError: Error, Equatable {
    case emptyTitle
    case notFound(UUID)
}
