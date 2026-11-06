//
//  VoxoSettingsView.swift
//  VoiceTodo
//
//  PLAN.md §7 settings screen.
//

import SwiftUI
import UserNotifications
import VoxoDesign
import VoxoShared

struct VoxoSettingsView: View {
    @EnvironmentObject private var store: TodoStore
    @EnvironmentObject private var session: PhoneSessionManager
    @EnvironmentObject private var reminders: ReminderService
    @Navigation private var navigation
    @StateObject private var viewModel = ViewModel()

    var body: some View {
        NavigationStack {
            Form {
                cycleSection
                notificationSection
                syncSection
                dataSection
                #if DEBUG
                    diagnosticsSection
                #endif
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { navigation.goBack() }
                }
            }
            .task { await viewModel.refresh(reminders: reminders) }
        }
    }

    private var cycleSection: some View {
        Section {
            Picker("Remind me every", selection: $store.globalIntervalMinutes) {
                ForEach(SyncSettings.allowedIntervals, id: \.self) { minutes in
                    Text(minutes.intervalLabel).tag(minutes)
                }
            }
        } header: {
            Text("Shared cycle")
        } footer: {
            Text("Applies to every task without its own cycle.")
        }
    }

    private var notificationSection: some View {
        Section {
            LabeledContent("Notifications") {
                Label(viewModel.authorizationText, systemImage: viewModel.authorizationIcon)
                    .labelStyle(.titleAndIcon)
                    .foregroundStyle(viewModel.isAuthorized ? VoxoColor.done : VoxoColor.overdue)
            }

            if !viewModel.isAuthorized {
                Button("Open Settings", action: viewModel.openSystemSettings)
            }
        } header: {
            Text("Reminders")
        } footer: {
            // The cap is a real product constraint, so it is stated plainly (PLAN.md §7).
            Text("iOS allows 64 pending notifications. Open Voxo at least once a day so upcoming reminders stay scheduled.")
        }
    }

    private var syncSection: some View {
        Section {
            LabeledContent("Watch app") {
                Label(
                    session.isWatchAppInstalled ? "Installed" : "Not installed",
                    systemImage: session.isWatchAppInstalled ? "checkmark.circle" : "exclamationmark.circle"
                )
                .labelStyle(.titleAndIcon)
                .foregroundStyle(session.isWatchAppInstalled ? VoxoColor.done : VoxoColor.textSecondary)
            }

            LabeledContent("Last sync") {
                if let last = session.lastSyncAt {
                    Text(last.formatted(date: .omitted, time: .standard))
                } else {
                    Text("Nothing received yet")
                        .foregroundStyle(VoxoColor.textSecondary)
                }
            }
        } header: {
            Text("Apple Watch")
        } footer: {
            Text("Changes travel between devices in the background. Nothing is lost while they are apart.")
        }
    }

    private var dataSection: some View {
        Section {
            Button("Clear finished tasks", role: .destructive) {
                viewModel.confirmClear = true
            }
            .disabled(store.completed.isEmpty)
        } footer: {
            Text("Finished tasks are removed from both devices. This cannot be undone.")
        }
        .confirmationDialog(
            "Clear \(store.completed.count) finished tasks?",
            isPresented: $viewModel.confirmClear,
            titleVisibility: .visible
        ) {
            Button("Clear", role: .destructive) { store.clearCompleted() }
            Button("Cancel", role: .cancel) {}
        }
    }

    #if DEBUG
        /// Phase 0/2 check: what is actually scheduled, and when reminders actually arrived.
        private var diagnosticsSection: some View {
            Section {
                LabeledContent("Scheduled now", value: "\(viewModel.pendingReminders.count)")

                ForEach(viewModel.pendingReminders, id: \.identifier) { request in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(request.content.body)
                            .font(VoxoFont.caption)
                        if let info = viewModel.describe(request) {
                            Text(info.cadence)
                                .font(VoxoFont.caption)
                                .foregroundStyle(VoxoColor.textSecondary)
                            Text("lần tới \(info.next)")
                                .font(VoxoFont.caption)
                                .foregroundStyle(VoxoColor.textSecondary)
                        }
                    }
                }

                if viewModel.deliveredReminders.isEmpty {
                    Text("Chưa nhận được lần nhắc nào")
                        .font(VoxoFont.caption)
                        .foregroundStyle(VoxoColor.textSecondary)
                } else {
                    ForEach(viewModel.deliveredReminders, id: \.date) { item in
                        Text("đã nhận \(item.date.formatted(date: .omitted, time: .standard))")
                            .font(VoxoFont.caption)
                    }
                }

                Button("Làm mới") {
                    Task { await viewModel.refresh(reminders: reminders) }
                }
            } header: {
                Text("Chẩn đoán nhắc việc")
            } footer: {
                Text("Chỉ hiện ở bản Dev. Đừng xoá thông báo Voxo nếu còn muốn xem giờ nhận.")
            }
        }
    #endif

}
