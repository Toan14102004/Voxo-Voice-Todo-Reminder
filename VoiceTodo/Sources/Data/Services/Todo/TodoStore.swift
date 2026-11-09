//
//  TodoStore.swift
//  VoiceTodo
//

import Combine
import Foundation
import VoxoShared

/// View-facing state for the iPhone app: views talk to this, it talks to `TodoRepository`.
/// Nothing in the UI layer ever sees a managed object (PLAN.md §2).
@MainActor
final class TodoStore: ObservableObject {
    @Published private(set) var active: [TodoDTO] = []
    @Published private(set) var completed: [TodoDTO] = []
    @Published private(set) var lists: [TodoListDTO] = []
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

    /// PLAN.md §2 wants this in an App Group. There is none: it buys nothing across two devices
    /// and would break the Manual provisioning profile.
    private static let intervalKey = "globalIntervalMinutes"

    private let repository: TodoRepository
    private let listRepository: TodoListRepository?
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

    /// Recomputes the whole reminder set (PLAN.md §5: cancel and re-plan, never patch).
    func rescheduleReminders() {
        guard let reminders else { return }
        let plans = ReminderScheduler.plan(todos: active, globalIntervalMinutes: globalIntervalMinutes)
        Task { await reminders.apply(plans) }
    }

    init(repository: TodoRepository, defaults: UserDefaults = .standard) {
        self.repository = repository
        listRepository = repository as? TodoListRepository
        self.defaults = defaults

        let stored = defaults.integer(forKey: Self.intervalKey)
        globalIntervalMinutes = SyncSettings.isValid(stored) ? stored : SyncSettings.defaultIntervalMinutes

        reload()
    }

    func reload() {
        perform {
            active = try repository.activeTodos()
            completed = try repository.completedTodos()
            lists = (try? listRepository?.lists()) ?? []
        }
        rescheduleReminders()
    }

    func add(
        title: String,
        intervalOverride: Int32 = 0,
        note: String? = nil,
        priority: TodoPriority = .none,
        dueAt: Date? = nil,
        listId: UUID? = nil,
        repeatRule: RepeatRule? = nil
    ) {
        perform {
            let now = Date()
            var created = try repository.create(title: title, intervalOverride: intervalOverride, now: now)
            if note != nil || priority != .none || dueAt != nil || listId != nil || repeatRule != nil {
                created.note = note
                created.priority = priority
                created.dueAt = dueAt
                created.listId = listId
                created.repeatRule = repeatRule
                try repository.update(created, now: now)
            }
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

    func reopen(_ todo: TodoDTO) {
        perform {
            try repository.reopen(id: todo.id, now: Date())
            reload()
            push(todo.id)
        }
    }

    /// Ticking a checkbox has to work both ways; done rows keep their checkbox in the design.
    func toggleDone(_ todo: TodoDTO) {
        todo.isDone ? reopen(todo) : complete(todo)
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

    /// Puts a todo back as it was, for the 4-second undo window (DS / Rules). Writes the whole
    /// previous record, so one call undoes a complete, a delete or a postpone alike.
    func restore(_ todo: TodoDTO) {
        perform {
            try repository.restore(todo, now: Date())
            reload()
            push(todo.id)
        }
    }

    /// Swipe-left action from the design: move the due date to tomorrow morning.
    func postponeToTomorrow(_ todo: TodoDTO) {
        perform {
            var updated = todo
            let tomorrow = Calendar.current.startOfDay(for: Date().addingTimeInterval(86_400))
            updated.dueAt = Calendar.current.date(byAdding: .hour, value: 9, to: tomorrow) ?? tomorrow
            try repository.update(updated, now: Date())
            reload()
            push(todo.id)
        }
    }

    /// Reads the published arrays first: a value fetched straight from the repository is correct
    /// but unobserved, so the view never re-renders.
    func todo(id: UUID) -> TodoDTO? {
        active.first { $0.id == id }
            ?? completed.first { $0.id == id }
            ?? (try? repository.todo(id: id))
    }

    func addList(name: String, colorHex: String, icon: String) {
        perform {
            _ = try listRepository?.createList(name: name, colorHex: colorHex, icon: icon, now: Date())
            reload()
        }
    }

    func deleteList(_ list: TodoListDTO) {
        perform {
            try listRepository?.deleteList(id: list.id, now: Date())
            reload()
        }
    }

    func taskCount(inList id: UUID) -> Int {
        active.filter { $0.listId == id }.count
    }

    func list(id: UUID) -> TodoListDTO? {
        lists.first { $0.id == id } ?? (try? listRepository?.list(id: id)) ?? nil
    }

    /// Sends one todo to the Watch, re-read from the repository so it receives exactly what was
    /// persisted, tombstones included.
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
    /// "1 hour" / "2 hours" / "1 day". Resolved through the catalog by hand: `Text(someString)`
    /// skips localization, so a raw `String` would stay English.
    var intervalLabel: String {
        let key: String
        switch self {
        case ..<60: key = "%lld min"
        case 60: key = "1 hour"
        case 1440: key = "1 day"
        case let value where value % 60 == 0: key = "%lld hours"
        default: key = "%lld min"
        }

        let format = key.localizedString
        guard format.contains("%lld") else { return format }
        let value = self < 60 || self % 60 != 0 ? self : self / 60
        return String(format: format, value)
    }
}
