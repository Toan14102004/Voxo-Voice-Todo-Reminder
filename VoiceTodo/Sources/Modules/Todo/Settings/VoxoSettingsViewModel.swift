//
//  VoxoSettingsViewModel.swift
//  VoiceTodo
//

import Foundation
import UIKit
import UserNotifications

extension VoxoSettingsView {
    @MainActor
    final class ViewModel: ObservableObject {
        @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
        @Published var confirmClear = false

        /// Phase 0/2 diagnostics: what is scheduled, and when reminders actually arrived.
        @Published var pendingReminders: [UNNotificationRequest] = []
        @Published var deliveredReminders: [(id: String, date: Date)] = []

        var isAuthorized: Bool { authorizationStatus == .authorized }

        var authorizationText: String {
            switch authorizationStatus {
            case .authorized, .provisional, .ephemeral: "On"
            case .denied: "Off"
            case .notDetermined: "Not asked"
            @unknown default: "Unknown"
            }
        }

        var authorizationIcon: String {
            isAuthorized ? "checkmark.circle" : "exclamationmark.circle"
        }

        func refresh(reminders: ReminderService) async {
            authorizationStatus = await UNUserNotificationCenter.current()
                .notificationSettings()
                .authorizationStatus
            pendingReminders = await reminders.pendingRequests()
            deliveredReminders = await reminders.deliveredReminders()
        }

        func openSystemSettings() {
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url)
        }

        /// "mỗi 60 phút · lặp: có" for one scheduled reminder.
        func describe(_ request: UNNotificationRequest) -> (cadence: String, next: String)? {
            guard let trigger = request.trigger as? UNTimeIntervalNotificationTrigger else { return nil }
            let cadence = "mỗi \(Int(trigger.timeInterval / 60)) phút · lặp: \(trigger.repeats ? "có" : "không")"
            let next = trigger.nextTriggerDate()?.formatted(date: .omitted, time: .standard) ?? "?"
            return (cadence, next)
        }
    }
}
