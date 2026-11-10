//
//  VoxoRootView.swift
//  VoiceTodo
//

import SwiftUI
import VoxoDesign
import VoxoShared

/// Root of the app. Every normal scheme launches into this; the template's own flow is reachable
/// only through `-templateUI`.
struct VoxoRootView: View {
    @StateObject private var store: TodoStore
    @StateObject private var session: PhoneSessionManager
    @StateObject private var reminders: ReminderService
    @StateObject private var settings = AppSettings()
    @ObservedObject private var language = LanguageManager.shared
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // -voxoSeed uses a throwaway in-memory store with sample content, for design review.
        let seeding = ProcessInfo.processInfo.arguments.contains("-voxoSeed")
        let stack = PersistenceStack(inMemory: seeding)
        let repository = CoreDataTodoRepository(stack: stack, device: .phone)

        #if DEBUG
            if seeding { Self.seed(into: repository) }
        #endif

        let store = TodoStore(repository: repository)
        // WCSession wakes the app in the background to deliver the Watch's ops, so the list is
        // already current when it opens.
        let session = PhoneSessionManager(repository: repository) { [weak store] in
            store?.reload()
        }
        store.attach(session: session)

        let reminders = ReminderService()
        store.attach(reminders: reminders)

        _store = StateObject(wrappedValue: store)
        _session = StateObject(wrappedValue: session)
        _reminders = StateObject(wrappedValue: reminders)
    }

    #if DEBUG
        private static func seed(into repository: TodoRepository) {
            let now = Date()
            // Hour-of-today for the Calendar tab; nil means the task has no slot in the day.
            let samples: [(String, Int32, Int?)] = [
                ("Call mum at eight tonight", 0, 20),
                ("Take the bins out", 0, nil),
                ("Pay the electricity bill", 1440, 14),
                ("Stretch for thirty minutes", 180, 7),
                ("Send Tuan the quote", 0, 10)
            ]
            let lists: [(String, String, String)] = [
                ("Cá nhân", "1E6FD0", "house"),
                ("Công việc", "F59E0B", "briefcase"),
                ("Mua sắm", "16A34A", "cart")
            ]
            // Staggered createdAt: lists sort by it, and three created at the same instant fall
            // back to comparing random ids, which reshuffles the sample on every launch.
            let created = lists.enumerated().compactMap { index, list in
                try? (repository as? TodoListRepository)?.createList(
                    name: list.0,
                    colorHex: list.1,
                    icon: list.2,
                    now: now.addingTimeInterval(TimeInterval(index))
                )
            }

            let startOfDay = Calendar.current.startOfDay(for: now)

            for (index, (title, interval, hour)) in samples.enumerated() {
                guard var todo = try? repository.create(title: title, intervalOverride: interval, now: now)
                else { continue }
                todo.listId = created[safe: index % max(created.count, 1)]?.id
                todo.priority = TodoPriority.allCases[index % TodoPriority.allCases.count]
                todo.dueAt = hour.map { startOfDay.addingTimeInterval(TimeInterval($0) * 3600) }
                try? repository.update(todo, now: now)
            }

            // Finished work spread over the past week, so the Stats tab has a streak, a bar per
            // day and a per-list split to show.
            let history: [(String, Int)] = [
                ("Book the flight to Da Nang", 0),
                ("Review the sprint board", 0),
                ("Water the plants", 1),
                ("Reply to Linh", 1),
                ("Buy coffee beans", 1),
                ("Weekly report", 2),
                ("Clean the desk", 3),
                ("Renew the gym pass", 3),
                ("Back up the laptop", 4),
                ("Call the dentist", 5)
            ]

            for (index, (title, daysAgo)) in history.enumerated() {
                let finishedAt = startOfDay
                    .addingTimeInterval(TimeInterval(-daysAgo) * 86400)
                    .addingTimeInterval(TimeInterval(9 + index % 8) * 3600)
                guard var todo = try? repository.create(title: title, intervalOverride: 0, now: finishedAt)
                else { continue }
                todo.listId = created[safe: index % max(created.count, 1)]?.id
                try? repository.update(todo, now: finishedAt)
                try? repository.complete(id: todo.id, now: finishedAt)
            }
        }
    #endif

    @State private var path = FlowPath()
    /// PLAN.md §7: onboarding runs once, then the app opens straight on Today.
    @State private var showOnboarding = Self.shouldShowOnboarding

    private static var shouldShowOnboarding: Bool {
        #if DEBUG
            // -skipOnboarding / -onboarding force either path, for screenshots.
            let args = ProcessInfo.processInfo.arguments
            if args.contains("-skipOnboarding") { return false }
            if args.contains("-onboarding") { return true }
        #endif
        return !OnboardingState.isComplete
    }

    var body: some View {
        if showOnboarding {
            OnboardingView { showOnboarding = false }
                .environment(\.locale, language.currentLocale)
        } else {
            mainFlow
        }
    }

    private var mainFlow: some View {
        FlowStack($path, withNavigation: true) {
            MainTabView()
                .modifier(NavigatorModifier())
                .flowDestination(for: TodayView.Coordinator.Navigation.self) { route in
                    switch route {
                    case .settings:
                        VoxoSettingsView()
                    case let .detail(id):
                        TaskDetailView(todoId: id)
                    }
                }
                .flowDestination(for: ListsView.Coordinator.Navigation.self) { route in
                    switch route {
                    case let .list(id):
                        ListDetailView(source: .list(id))
                    case let .filter(raw):
                        if let filter = ListsView.SmartFilter(rawValue: raw) {
                            ListDetailView(source: .filter(filter))
                        }
                    }
                }
                .flowDestination(for: TodayView.Coordinator.FullScreen.self) { route in
                    switch route {
                    case .quickAdd:
                        QuickAddView()
                    }
                }
        }
            .environmentObject(store)
            .environmentObject(session)
            .environmentObject(reminders)
            .environmentObject(settings)
            .tint(VoxoColor.primary)
            // nil for "Match system", which is the default.
            .preferredColorScheme(settings.appearance.colorScheme)
            // Tidy is bilingual VI/EN and switches in-app, so the locale comes from
            // LanguageManager rather than the system (PLAN.md §0).
            .environment(\.locale, language.currentLocale)
            .environment(\.layoutDirection, language.layoutDirection)
            .onChange(of: showOnboarding) { isShowing in
                if !isShowing { OnboardingState.isComplete = true }
            }
            .task {
                #if DEBUG
                    // -lang vi | -lang en: forces the in-app language, for screenshots and for
                    // checking both halves of the bilingual UI without touching device settings.
                    let args = ProcessInfo.processInfo.arguments
                    if let i = args.firstIndex(of: "-lang"), i + 1 < args.count {
                        LanguageManager.shared.changeLanguage(LanguageManager.resolve(args[i + 1]))
                    }
                #endif
                reminders.soundEnabled = settings.soundEnabled
                session.start()
                await reminders.refresh()
                // The seeded run skips the prompt: its system alert covers the screen under review.
                let seeded = ProcessInfo.processInfo.arguments.contains("-voxoSeed")
                if reminders.authorizationStatus == .notDetermined, !seeded {
                    await reminders.requestAuthorization()
                }
                // Re-plan after the permission answer: the attempt during init ran before it.
                store.rescheduleReminders()
            }
            .onChange(of: language.currentLanguageCode) { code in
                // The watch has no language switch of its own, so it follows this one.
                session.pushSettings(
                    globalIntervalMinutes: store.globalIntervalMinutes,
                    languageCode: code
                )
            }
            .onChange(of: settings.soundEnabled) { enabled in
                reminders.soundEnabled = enabled
                // Pending notifications carry their sound setting from when they were scheduled,
                // so the switch only takes effect after a re-plan.
                store.rescheduleReminders()
            }
            .onChange(of: scenePhase) { phase in
                // PLAN.md §5: re-plan whenever the app comes forward.
                if phase == .active { store.rescheduleReminders() }
            }
    }
}

private extension Array {
    /// Bounds-checked access, so seeding never traps when the sample arrays differ in length.
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
