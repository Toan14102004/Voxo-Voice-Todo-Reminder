//
//  VoxoRootView.swift
//  VoiceTodo
//

import SwiftUI
import VoxoDesign
import VoxoShared

/// Root of the real Voxo UI.
///
/// Reached today through the `VoiceTodo-Voxo` scheme (`-voxoUI`). Phase 6 replaces the template's
/// placeholder `ContentView` with this for good.
struct VoxoRootView: View {
    @StateObject private var store: TodoStore
    @StateObject private var session: PhoneSessionManager
    @StateObject private var reminders: ReminderService
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
        // WCSession wakes this app in the background to deliver the Watch's ops, so the list is
        // already up to date by the time it is opened.
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
            let samples: [(String, Int32)] = [
                ("Call mum at eight tonight", 0),
                ("Take the bins out", 0),
                ("Pay the electricity bill", 1440),
                ("Stretch for thirty minutes", 180),
                ("Send Tuan the quote", 0)
            ]
            for (title, interval) in samples {
                _ = try? repository.create(title: title, intervalOverride: interval, now: now)
            }

            if let finished = try? repository.create(title: "Book the flight to Da Nang", intervalOverride: 0, now: now.addingTimeInterval(-7200)) {
                try? repository.complete(id: finished.id, now: now.addingTimeInterval(-3600))
            }
        }
    #endif

    var body: some View {
        TodoListView()
            .environmentObject(store)
            .environmentObject(session)
            .environmentObject(reminders)
            .tint(VoxoColor.accent)
            .task {
                session.start()
                await reminders.refresh()
                if reminders.authorizationStatus == .notDetermined {
                    await reminders.requestAuthorization()
                }
                // Always re-plan after the permission answer: the attempt made during init ran
                // before the user had decided, so nothing could be scheduled then.
                store.rescheduleReminders()
            }
            .onChange(of: scenePhase) { phase in
                // PLAN.md §5: re-plan whenever the app comes forward.
                if phase == .active { store.rescheduleReminders() }
            }
    }
}
