//
//  TodoStore.swift
//  VoiceTodo
//

import Combine
import Foundation
import VoxoShared

/// View-facing state for the iPhone app.
///
/// Views talk to this; it talks to `TodoRepository`. Nothing in the UI layer ever sees a
/// managed object (PLAN.md §2).
@MainActor
final class TodoStore: ObservableObject {
    @Published private(set) var active: [TodoDTO] = []
    @Published private(set) var completed: [TodoDTO] = []
    @Published private(set) var lastError: String?
    @Published var globalIntervalMinutes: Int {
        didSet {
            guard SyncSettings.isValid(globalIntervalMinutes) else {
                globalIntervalMinutes = oldValue
                return
            }
            defaults.set(globalIntervalMinutes, forKey: Self.intervalKey)
            session?.pushSettings(globalIntervalMinutes: globalIntervalMinutes)
            rescheduleReminders()
        }
    }

    /// PLAN.md §2 wants this in an App Group. There is no App Group yet — it buys nothing across
    /// two devices, and adding it would break the Manual provisioning profile. Revisit in Phase 5.
    private static let intervalKey = "globalIntervalMinutes"

    private let repository: TodoRepository
    private let defaults: UserDefaults
    private var session: PhoneSessionManager?
    private var reminders: ReminderService?

    /// Set once the session manager exists, so settings changes reach the Watch.
    func attach(session: PhoneSessionManager) {
        self.session = session
        session.pushSettings(globalIntervalMinutes: globalIntervalMinutes)
    }

    func attach(reminders: ReminderService) {
        self.reminders = reminders
        rescheduleReminders()
    }

    /// Recomputes the whole reminder set from the current list (PLAN.md §5: cancel and re-plan,
    /// never patch individual notifications).
    func rescheduleReminders() {
        guard let reminders else { return }
        let plans = ReminderScheduler.plan(todos: active, globalIntervalMinutes: globalIntervalMinutes)
        Task { await reminders.apply(plans) }
    }

    init(repository: TodoRepository, defaults: UserDefaults = .standard) {
        self.repository = repository
        self.defaults = defaults

        let stored = defaults.integer(forKey: Self.intervalKey)
        globalIntervalMinutes = SyncSettings.isValid(stored) ? stored : SyncSettings.defaultIntervalMinutes

        reload()
    }

    func reload() {
        perform {
            active = try repository.activeTodos()
            completed = try repository.completedTodos()
        }
        rescheduleReminders()
    }

    func add(title: String, intervalOverride: Int32 = 0) {
        perform {
            let created = try repository.create(title: title, intervalOverride: intervalOverride, now: Date())
            reload()
            push(created.id)
        }
    }

    func update(_ todo: TodoDTO) {
        perform {
            try repository.update(todo, now: Date())
            reload()
            push(todo.id)
        }
    }

    func complete(_ todo: TodoDTO) {
        perform {
            try repository.complete(id: todo.id, now: Date())
            reload()
            push(todo.id)
        }
    }

    func delete(_ todo: TodoDTO) {
        perform {
            try repository.delete(id: todo.id, now: Date())
            reload()
            push(todo.id)
        }
    }

    /// Settings' "Clear completed" — a soft delete, so the Watch learns about it too.
    func clearCompleted() {
        perform {
            let now = Date()
            let ids = completed.map(\.id)
            for id in ids {
                try repository.delete(id: id, now: now)
            }
            reload()
            ids.forEach(push)
        }
    }

    /// Sends the stored state of one todo to the Watch. Reads it back from the repository so the
    /// Watch always receives exactly what was persisted, tombstones included.
    private func push(_ id: UUID) {
        guard let session, let stored = try? repository.todo(id: id) else { return }
        session.push(stored)
    }

    /// Effective reminder cycle for a todo, in minutes (PLAN.md §5 rule 2).
    func interval(for todo: TodoDTO) -> Int {
        todo.intervalOverride > 0 ? Int(todo.intervalOverride) : globalIntervalMinutes
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

extension Int {
    /// "60 minutes" / "2 hours" / "1 day" — used wherever an interval is shown.
    var intervalLabel: String {
        switch self {
        case ..<60: "\(self) min"
        case 60: "1 hour"
        case 1440: "1 day"
        case let value where value % 60 == 0: "\(value / 60) hours"
        default: "\(self) min"
        }
    }
}
