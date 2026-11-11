//
//  VoiceTodoWatchApp.swift
//  VoiceTodoWatch
//

import SwiftUI
import VoxoShared

@main
struct VoiceTodoWatchApp: App {
    @StateObject private var store: WatchTodoStore
    @StateObject private var session: WatchSessionManager

    init() {
        // -voxoSeed: throwaway in-memory store with sample content, for design review. Same flag
        // as the phone app.
        let seeding = ProcessInfo.processInfo.arguments.contains("-voxoSeed")
        let stack = PersistenceStack(inMemory: seeding)
        let repository = CoreDataTodoRepository(stack: stack, device: .watch)

        #if DEBUG
            if seeding { Self.seed(into: repository) }
        #endif

        let store = WatchTodoStore(repository: repository)
        // Incoming changes from the phone reload the list.
        let session = WatchSessionManager(repository: repository) { [weak store] in
            store?.reload()
        }
        store.attach(session: session)

        _store = StateObject(wrappedValue: store)
        _session = StateObject(wrappedValue: session)
    }

    @ViewBuilder
    private var main: some View {
        #if DEBUG
            // Phase 0 is not signed off yet, so the dictation probe stays one page away.
            TabView {
                WatchTodoListView(store: store)
                DictationProbeView()
            }
            .tabViewStyle(.verticalPage)
        #else
            WatchTodoListView(store: store)
        #endif
    }

    #if DEBUG
        private static func seed(into repository: CoreDataTodoRepository) {
            let now = Date()
            let startOfDay = Calendar.current.startOfDay(for: now)

            let lists = [
                ("Công việc", "F59E0B", "briefcase"),
                ("Mua sắm", "16A34A", "cart"),
                ("Cá nhân", "1E6FD0", "house")
            ]
            let created = lists.enumerated().compactMap { index, list in
                try? repository.createList(
                    name: list.0,
                    colorHex: list.1,
                    icon: list.2,
                    now: now.addingTimeInterval(TimeInterval(index))
                )
            }

            let samples: [(String, TodoPriority, Int?, Int)] = [
                ("Họp sprint review", .high, 10, 0),
                ("Mua sữa và trứng", .low, 14, 1),
                ("Gọi điện cho mẹ", .none, 20, 2)
            ]
            for (title, priority, hour, listIndex) in samples {
                guard var todo = try? repository.create(title: title, intervalOverride: 0, now: now)
                else { continue }
                todo.priority = priority
                todo.dueAt = hour.map { startOfDay.addingTimeInterval(TimeInterval($0) * 3600) }
                todo.listId = created.indices.contains(listIndex) ? created[listIndex].id : nil
                try? repository.update(todo, now: now)
            }

            let finishedAt = startOfDay.addingTimeInterval(7 * 3600 + 40 * 60)
            if let done = try? repository.create(title: "Chạy bộ 5km", intervalOverride: 0, now: finishedAt) {
                try? repository.complete(id: done.id, now: finishedAt)
            }
        }
    #endif

    /// Shown once per launch, then never again until the app is reopened.
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            Group {
                if showSplash {
                    WatchSplashView { showSplash = false }
                } else {
                    main
                }
            }
            .environmentObject(session)
            .environment(\.locale, session.locale)
            .task { session.start() }
        }
    }
}
