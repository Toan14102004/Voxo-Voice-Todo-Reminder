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
        let stack = PersistenceStack()
        let repository = CoreDataTodoRepository(stack: stack, device: .watch)
        let store = WatchTodoStore(repository: repository)
        // Incoming changes from the phone reload the list.
        let session = WatchSessionManager(repository: repository) { [weak store] in
            store?.reload()
        }
        store.attach(session: session)

        _store = StateObject(wrappedValue: store)
        _session = StateObject(wrappedValue: session)
    }

    var body: some Scene {
        WindowGroup {
            #if DEBUG
                // Phase 0 is not signed off yet, so the dictation probe stays one tab away.
                TabView {
                    WatchTodoListView(store: store)
                    DictationProbeView()
                }
                .tabViewStyle(.verticalPage)
                .environmentObject(session)
                .task { session.start() }
            #else
                WatchTodoListView(store: store)
                    .environmentObject(session)
                    .task { session.start() }
            #endif
        }
    }
}
