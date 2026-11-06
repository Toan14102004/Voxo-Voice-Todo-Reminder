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
    @Published private(set) var pendingSyncCount: Int = 0
    @Published private(set) var lastError: String?

    private let repository: TodoRepository
    private let outbox: SyncOutbox
    private var session: WatchSessionManager?

    init(repository: TodoRepository & SyncOutbox) {
        self.repository = repository
        outbox = repository
        reload()
    }

    func attach(session: WatchSessionManager) {
        self.session = session
    }

    func reload() {
        perform {
            active = try repository.activeTodos()
            pendingSyncCount = try outbox.pendingOpCount()
        }
    }

    func add(title: String) {
        perform {
            try repository.create(title: title, intervalOverride: 0, now: Date())
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
