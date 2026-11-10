//
//  ReminderService.swift
//  VoiceTodo
//
//  Turns ReminderScheduler's plans into real notifications. PLAN.md §5.
//

import Foundation
import UserNotifications
import VoxoShared

@MainActor
final class ReminderService: ObservableObject {
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published private(set) var scheduledCount: Int = 0
    @Published private(set) var lastAppliedAt: Date?
    @Published private(set) var lastError: String?

    private let center = UNUserNotificationCenter.current()
    private let defaults: UserDefaults
    private static let appliedKey = "voxo.reminder.applied"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func refresh() async {
        authorizationStatus = await center.notificationSettings().authorizationStatus
        scheduledCount = await pendingRequests().count
    }

    /// True once notifications may actually be delivered.
    var canSchedule: Bool {
        switch authorizationStatus {
        case .authorized, .provisional, .ephemeral: true
        default: false
        }
    }

    /// Mirrors `AppSettings.soundEnabled`. Read when a notification is built, so a change only
    /// reaches already-scheduled reminders after a re-plan.
    var soundEnabled = true

    @discardableResult
    func requestAuthorization() async -> Bool {
        var granted = false
        do {
            granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            lastError = error.localizedDescription
        }
        await refresh()
        return granted
    }

    /// Reconciles the scheduled notifications with `plans`.
    ///
    /// Plans that did not change are left alone **on purpose**. A repeating trigger restarts its
    /// clock when re-added, so blindly rescheduling on every app launch would push the next
    /// reminder out by a full cycle every time and it would never fire.
    func apply(_ plans: [ReminderPlan]) async {
        await refresh()
        guard canSchedule else {
            // Nothing to do yet; the caller re-applies once permission is granted.
            #if DEBUG
                print("[Voxo] bỏ qua đặt lịch — chưa có quyền thông báo (\(authorizationStatus.rawValue))")
            #endif
            return
        }

        let previous = loadApplied()
        guard previous != plans else {
            await refresh()
            return
        }

        let planIds = Set(plans.map(\.id))
        let stale = await pendingRequests()
            .map(\.identifier)
            .filter { !planIds.contains($0) }
        if !stale.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: stale)
        }

        let unchanged = Set(previous.filter { plans.contains($0) }.map(\.id))

        for plan in plans where !unchanged.contains(plan.id) {
            center.removePendingNotificationRequests(withIdentifiers: [plan.id])
            await add(plan)
        }

        // Save only what iOS actually accepted. Saving the intended plans would make the
        // "unchanged, skip" guard above permanently skip plans that failed to schedule — e.g.
        // everything attempted before the user granted permission.
        let live = Set(await pendingRequests().map(\.identifier))
        save(plans.filter { live.contains($0.id) })

        lastAppliedAt = Date()
        await refresh()

        #if DEBUG
            let scheduled = await pendingRequests()
            print("[Voxo] đặt lịch \(scheduled.count)/\(plans.count) nhắc việc:")
            if let lastError { print("[Voxo]   lỗi gần nhất: \(lastError)") }
            for request in scheduled {
                let every = (request.trigger as? UNTimeIntervalNotificationTrigger)
                    .map { "mỗi \(Int($0.timeInterval / 60))p, lặp=\($0.repeats)" } ?? "?"
                let next = (request.trigger as? UNTimeIntervalNotificationTrigger)?
                    .nextTriggerDate()?.formatted(date: .omitted, time: .standard) ?? "?"
                print("[Voxo]   \(request.identifier) · \(request.content.body) · \(every) · lần tới \(next)")
            }
        #endif
    }

    /// Drops every Voxo reminder. Used when the list empties.
    func cancelAll() async {
        let ids = await pendingRequests().map(\.identifier)
        center.removePendingNotificationRequests(withIdentifiers: ids)
        save([])
        await refresh()
    }

    func pendingRequests() async -> [UNNotificationRequest] {
        await center.pendingNotificationRequests()
            .filter { $0.identifier.hasPrefix(ReminderPlan.identifierPrefix) }
    }

    /// Delivery times iOS recorded, for checking the reminders actually fired.
    func deliveredReminders() async -> [(id: String, date: Date)] {
        await center.deliveredNotifications()
            .filter { $0.request.identifier.hasPrefix(ReminderPlan.identifierPrefix) }
            .map { ($0.request.identifier, $0.date) }
            .sorted { $0.date < $1.date }
    }

    // MARK: - Private

    private func add(_ plan: ReminderPlan) async {
        let content = UNMutableNotificationContent()
        content.title = plan.title
        content.body = plan.body
        // Settings → "Âm thanh & rung". A silent reminder still shows and still badges.
        content.sound = soundEnabled ? .default : nil
        content.userInfo = ["todoId": plan.todoId.uuidString]

        let request = UNNotificationRequest(
            identifier: plan.id,
            content: content,
            // repeats: true keeps this to a single pending slot forever (PLAN.md §1.7).
            trigger: UNTimeIntervalNotificationTrigger(
                timeInterval: TimeInterval(plan.intervalMinutes * 60),
                repeats: true
            )
        )

        do {
            try await center.add(request)
        } catch {
            lastError = "Không đặt được lịch \(plan.id): \(error.localizedDescription)"
        }
    }

    private func loadApplied() -> [ReminderPlan] {
        guard let data = defaults.data(forKey: Self.appliedKey),
              let decoded = try? JSONDecoder().decode([StoredPlan].self, from: data) else { return [] }
        return decoded.map(\.plan)
    }

    private func save(_ plans: [ReminderPlan]) {
        guard let data = try? JSONEncoder().encode(plans.map(StoredPlan.init)) else { return }
        defaults.set(data, forKey: Self.appliedKey)
    }
}

/// `ReminderPlan` stays Codable-free in the shared module; persistence is an app concern.
private struct StoredPlan: Codable {
    let id: String
    let todoId: UUID
    let title: String
    let body: String
    let intervalMinutes: Int
    let sharedCount: Int?

    init(_ plan: ReminderPlan) {
        id = plan.id
        todoId = plan.todoId
        title = plan.title
        body = plan.body
        intervalMinutes = plan.intervalMinutes
        if case let .shared(count) = plan.kind { sharedCount = count } else { sharedCount = nil }
    }

    var plan: ReminderPlan {
        ReminderPlan(
            id: id,
            kind: sharedCount.map { ReminderPlan.Kind.shared(todoCount: $0) } ?? .single,
            todoId: todoId,
            title: title,
            body: body,
            intervalMinutes: intervalMinutes
        )
    }
}
