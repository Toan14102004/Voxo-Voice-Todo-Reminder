//
//  WatchTodoListView.swift
//  VoiceTodoWatch
//
//  PLAN.md §7 Apple Watch: unfinished todos oldest first, add by dictation, swipe to complete,
//  tap for detail, and a sync-pending line at the bottom.
//

import SwiftUI
import VoxoDesign
import VoxoShared

struct WatchTodoListView: View {
    @StateObject private var store: WatchTodoStore
    @EnvironmentObject private var session: WatchSessionManager
    @State private var isAdding = false

    init(store: WatchTodoStore) {
        _store = StateObject(wrappedValue: store)
    }

    var body: some View {
        NavigationStack {
            List {
                addButton

                ForEach(store.active) { todo in
                    NavigationLink {
                        WatchTodoDetailView(todo: todo, store: store)
                    } label: {
                        TodoRow(todo: todo)
                    }
                    .swipeActions(edge: .trailing) {
                        Button {
                            store.complete(todo)
                        } label: {
                            Label("Done", systemImage: "checkmark")
                        }
                        .tint(VoxoColor.done)
                    }
                }

                if store.active.isEmpty {
                    Text("No tasks yet. Tap Add and speak one.")
                        .font(VoxoFont.caption)
                        .foregroundStyle(VoxoColor.textSecondary)
                }

                syncStatus
            }
            .navigationTitle("Voxo")
            .sheet(isPresented: $isAdding) {
                WatchAddTodoView { title in store.add(title: title) }
            }
        }
        .tint(VoxoColor.accent)
    }

    private var addButton: some View {
        Button {
            isAdding = true
        } label: {
            Label("Add", systemImage: "mic.fill")
                .font(VoxoFont.headline)
                .frame(maxWidth: .infinity)
        }
        .tint(VoxoColor.accent)
    }

    @ViewBuilder
    private var syncStatus: some View {
        // Only shown when something is actually waiting, so a healthy state stays quiet.
        if session.pendingOpCount > 0 {
            Label("Waiting to sync: \(session.pendingOpCount)", systemImage: "arrow.triangle.2.circlepath")
                .font(VoxoFont.caption)
                .foregroundStyle(VoxoColor.textSecondary)
        }
    }
}
