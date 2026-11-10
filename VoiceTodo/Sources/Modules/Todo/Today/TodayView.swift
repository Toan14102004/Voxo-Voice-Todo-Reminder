//
//  TodayView.swift
//  VoiceTodo
//
//  Design: board "Tidy – Todo App", frame "VI / 2 Hôm nay".
//

import SwiftUI
import VoxoDesign
import VoxoShared

struct TodayView: View {
    @EnvironmentObject private var store: TodoStore
    @Environment(\.locale) private var locale
    @StateObject private var viewModel = ViewModel()
    @StateObject private var undo = UndoCenter()

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // A List, not a ScrollView: `.swipeActions` is List-only and silently does nothing
            // anywhere else.
            List {
                Section {
                    header
                    VoxoProgressCard(done: store.completed.count, total: viewModel.totalToday(store))
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: VoxoSpacing.s, leading: VoxoSpacing.screenMargin,
                                          bottom: VoxoSpacing.s, trailing: VoxoSpacing.screenMargin))

                ForEach(TodaySection.allCases) { section in
                    let items = viewModel.items(in: section, store: store)
                    if !items.isEmpty {
                        Section {
                            ForEach(items) { todo in
                                row(todo, isOverdue: section.isAlarming)
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                                    .listRowInsets(EdgeInsets(
                                        top: VoxoSpacing.xs, leading: VoxoSpacing.screenMargin,
                                        bottom: VoxoSpacing.xs, trailing: VoxoSpacing.screenMargin
                                    ))
                            }
                        } header: {
                            sectionHeader(section, count: items.count)
                        }
                    }
                }

                // Keeps the last row clear of the FAB.
                Color.clear
                    .frame(height: 80)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(VoxoColor.background)

            VoxoFAB { viewModel.addTodo() }
                .padding(.trailing, VoxoSpacing.screenMargin)
                .padding(.bottom, VoxoSpacing.xl)
        }
        .safeAreaInset(edge: .bottom) {
            if let pending = undo.pending {
                UndoBanner(pending: pending) { undo.performUndo() }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: undo.pending?.id)
        #if DEBUG
            // -openQuickAdd opens the sheet on launch, for screenshots without tapping the FAB.
            .onAppear {
                let args = ProcessInfo.processInfo.arguments
                if args.contains("-openQuickAdd") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { viewModel.addTodo() }
                }
                if args.contains("-openDetail"), let first = store.active.first {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { viewModel.open(first) }
                }
                if args.contains("-openSettings") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { viewModel.openSettings() }
                }
            }
        #endif
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: VoxoSpacing.xs) {
                Text(verbatim: viewModel.dateLine(locale))
                    .font(VoxoFont.caption)
                    .foregroundStyle(VoxoColor.textSecondary)
                Text(viewModel.greeting)
                    .font(VoxoFont.display)
                    .foregroundStyle(VoxoColor.textPrimary)
            }

            Spacer(minLength: VoxoSpacing.m)

            // The avatar is the way into Settings — the design gives the screen no other entry,
            // and its profile card is the same circle enlarged.
            Button { viewModel.openSettings() } label: {
                Text(verbatim: viewModel.initial)
                    .font(VoxoFont.headline)
                    .foregroundStyle(VoxoColor.primary)
                    .frame(width: 44, height: 44)
                    .background(VoxoColor.primaryTint)
                    .clipShape(Circle())
            }
            .accessibilityLabel("Settings")
        }
        .padding(.top, VoxoSpacing.s)
    }

    // MARK: - Groups

    private func sectionHeader(_ section: TodaySection, count: Int) -> some View {
        HStack(spacing: VoxoSpacing.xs) {
            Text(section.title)
            Text(verbatim: "· \(count)")
        }
        .font(VoxoFont.overline)
        .textCase(.uppercase)
        .foregroundStyle(section.isAlarming ? VoxoColor.danger : VoxoColor.textSecondary)
        .padding(.leading, VoxoSpacing.screenMargin)
        .padding(.top, VoxoSpacing.m)
    }

    private func row(_ todo: TodoDTO, isOverdue: Bool) -> some View {
        TodoRow(
            todo: todo,
            meta: viewModel.meta(for: todo, store: store, locale: locale),
            isOverdue: isOverdue,
            onToggle: { toggleDone(todo) }
        )
        .onTapGesture { viewModel.open(todo) }
        // DS / Rules: swipe right completes, swipe left postpones or deletes.
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button { toggleDone(todo) } label: {
                Label(todo.isDone ? "Reopen" : "Done",
                      systemImage: todo.isDone ? "arrow.uturn.backward" : VoxoIcon.check)
            }
            .tint(todo.isDone ? VoxoColor.textSecondary : VoxoColor.success)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) { delete(todo) } label: {
                Label("Delete", systemImage: "trash")
            }
            Button { postpone(todo) } label: {
                Label("Tomorrow", systemImage: "arrow.uturn.right")
            }
            .tint(VoxoColor.priorityMedium)
        }
    }

    // MARK: - Actions, each undoable for 4 seconds

    private func toggleDone(_ todo: TodoDTO) {
        let before = todo
        let wasDone = todo.isDone
        store.toggleDone(todo)
        undo.offer(wasDone ? "Reopened" : "Marked done") { store.restore(before) }
    }

    private func delete(_ todo: TodoDTO) {
        let before = todo
        store.delete(todo)
        undo.offer("Task deleted") { store.restore(before) }
    }

    private func postpone(_ todo: TodoDTO) {
        let before = todo
        store.postponeToTomorrow(todo)
        undo.offer("Moved to tomorrow") { store.restore(before) }
    }
}
