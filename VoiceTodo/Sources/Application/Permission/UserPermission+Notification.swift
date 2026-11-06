//
//  UserPermission+Notification.swift
//  VoiceTodo
//
//  Created by Toan Nguyen on 13/2/25.
//

import Foundation
import UserNotifications

protocol SystemNotificationsSettings {
    var authorizationStatus: UNAuthorizationStatus { get } // get status of notification
}

protocol SystemNotificationsCenter {
    func currentSettings() async -> SystemNotificationsSettings // get setting notification
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool // request notification
}

extension UNNotificationSettings: SystemNotificationsSettings {}

extension UNUserNotificationCenter: SystemNotificationsCenter {
    func currentSettings() async -> any SystemNotificationsSettings {
        await notificationSettings()
    }
}

extension UNAuthorizationStatus {
    var map: Permission.Status {
        switch self {
        case .denied: return .denied
        case .authorized: return .granted
        case .notDetermined, .provisional, .ephemeral: return .notRequested
        @unknown default: return .notRequested
        }
    }
}
