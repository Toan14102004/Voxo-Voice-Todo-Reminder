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
    @Environment(\.dismiss) private var dismiss

    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @State private var confirmClear = false
    @State private var pending: [UNNotificationRequest] = []
    @State private var delivered: [(id: String, date: Date)] = []

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
                    Button("Done") { dismiss() }
                }
            }
            .task {
                await refreshAuthorization()
                await loadDiagnostics()
            }
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
                Label(authorizationText, systemImage: authorizationIcon)
                    .labelStyle(.titleAndIcon)
                    .foregroundStyle(authorizationStatus == .authorized ? VoxoColor.done : VoxoColor.overdue)
            }

            if authorizationStatus != .authorized {
                Button("Open Settings", action: openSystemSettings)
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
                confirmClear = true
            }
            .disabled(store.completed.isEmpty)
        } footer: {
            Text("Finished tasks are removed from both devices. This cannot be undone.")
        }
        .confirmationDialog(
            "Clear \(store.completed.count) finished tasks?",
            isPresented: $confirmClear,
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
                LabeledContent("Scheduled now", value: "\(pending.count)")

                ForEach(pending, id: \.identifier) { request in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(request.content.body)
                            .font(VoxoFont.caption)
                        if let trigger = request.trigger as? UNTimeIntervalNotificationTrigger {
                            Text("mỗi \(Int(trigger.timeInterval / 60)) phút · lặp: \(trigger.repeats ? "có" : "không")")
                                .font(VoxoFont.caption)
                                .foregroundStyle(VoxoColor.textSecondary)
                            if let next = trigger.nextTriggerDate() {
                                Text("lần tới \(next.formatted(date: .omitted, time: .standard))")
                                    .font(VoxoFont.caption)
                                    .foregroundStyle(VoxoColor.textSecondary)
                            }
                        }
                    }
                }

                if delivered.isEmpty {
                    Text("Chưa nhận được lần nhắc nào")
                        .font(VoxoFont.caption)
                        .foregroundStyle(VoxoColor.textSecondary)
                } else {
                    ForEach(delivered, id: \.date) { item in
                        Text("đã nhận \(item.date.formatted(date: .omitted, time: .standard))")
                            .font(VoxoFont.caption)
                    }
                }

                Button("Làm mới") {
                    Task { await loadDiagnostics() }
                }
            } header: {
                Text("Chẩn đoán nhắc việc")
            } footer: {
                Text("Chỉ hiện ở bản Dev. Đừng xoá thông báo Voxo nếu còn muốn xem giờ nhận.")
            }
        }
    #endif

    private func loadDiagnostics() async {
        pending = await reminders.pendingRequests()
        delivered = await reminders.deliveredReminders()
    }

    private var authorizationText: String {
        switch authorizationStatus {
        case .authorized, .provisional, .ephemeral: "On"
        case .denied: "Off"
        case .notDetermined: "Not asked"
        @unknown default: "Unknown"
        }
    }

    private var authorizationIcon: String {
        authorizationStatus == .authorized ? "checkmark.circle" : "exclamationmark.circle"
    }

    private func refreshAuthorization() async {
        authorizationStatus = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
