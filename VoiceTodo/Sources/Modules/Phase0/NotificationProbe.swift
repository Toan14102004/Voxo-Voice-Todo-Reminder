//
//  NotificationProbe.swift
//  VoiceTodo
//
//  Phase 0 harness. Throwaway code: delete once PLAN.md Phase 0 is signed off.
//

import Combine
import Foundation
import UserNotifications

/// One scheduled probe notification and, after collection, when it actually arrived.
struct ProbeFire: Codable, Identifiable {
    let id: String          // "phase0-s<series>-f<index>", mirrors PLAN.md's "todo-<id>-<n>" shape
    let series: Int
    let index: Int
    let plannedAt: Date
    var deliveredAt: Date?

    var delta: TimeInterval? {
        guard let deliveredAt else { return nil }
        return deliveredAt.timeIntervalSince(plannedAt)
    }

    /// PLAN.md §0 tolerance.
    var onTime: Bool {
        guard let delta else { return false }
        return abs(delta) <= 5 * 60
    }
}

struct ProbeRun: Codable {
    let startedAt: Date
    let intervalMinutes: Int
    let series: Int
    let firesPerSeries: Int
    /// What iOS actually accepted, read back from `getPendingNotificationRequests` after scheduling.
    var registeredPending: Int
    var fires: [ProbeFire]

    var requested: Int { series * firesPerSeries }
    var deliveredCount: Int { fires.filter { $0.deliveredAt != nil }.count }
    var onTimeCount: Int { fires.filter(\.onTime).count }
    var lastPlannedAt: Date? { fires.map(\.plannedAt).max() }

    /// Share of *delivered-and-measurable* fires that landed inside the tolerance.
    var onTimeRate: Double? {
        guard deliveredCount > 0 else { return nil }
        return Double(onTimeCount) / Double(deliveredCount)
    }

    var worstDelta: TimeInterval? {
        fires.compactMap(\.delta).max(by: { abs($0) < abs($1) })
    }
}

/// Measurement B from PLAN.md §0: a single `repeats: true` trigger, the mechanism v1 ships.
struct RepeatRun: Codable {
    let startedAt: Date
    let intervalMinutes: Int
    var lastDeliveredAt: Date?
    var stillPending: Bool = true

    /// How many times it should have fired by `now`.
    func expectedFires(now: Date) -> Int {
        Int(now.timeIntervalSince(startedAt)) / (intervalMinutes * 60)
    }

    /// The slot the newest delivery should have landed in.
    func expectedLastFire(now: Date) -> Date? {
        let count = expectedFires(now: now)
        guard count > 0 else { return nil }
        return startedAt.addingTimeInterval(TimeInterval(count * intervalMinutes * 60))
    }

    /// Drift of the newest delivery against its slot. Nil until something has been delivered.
    func drift(now: Date) -> TimeInterval? {
        guard let lastDeliveredAt, let expected = expectedLastFire(now: now) else { return nil }
        return lastDeliveredAt.timeIntervalSince(expected)
    }

    /// PLAN.md §0 bar for measurement B: still scheduled, and the last fire inside ±5 minutes.
    func verdict(now: Date) -> String {
        guard expectedFires(now: now) > 0 else { return "Chưa tới nhịp đầu tiên" }
        guard lastDeliveredAt != nil else { return "KHÔNG ĐẠT — chưa nhận được lần nào" }
        guard let drift = drift(now: now) else { return "—" }
        if !stillPending { return "KHÔNG ĐẠT — iOS đã bỏ lịch lặp" }
        return abs(drift) <= 300
            ? String(format: "ĐẠT — lệch %+.0f giây", drift)
            : String(format: "KHÔNG ĐẠT — lệch %+.0f giây", drift)
    }
}

@MainActor
final class NotificationProbe: ObservableObject {
    private static let storageKey = "phase0.notification.run"
    private static let repeatKey = "phase0.notification.repeat"
    private static let identifierPrefix = "phase0-"
    private static let repeatIdentifier = "phase0-repeat"

    @Published private(set) var run: ProbeRun?
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published private(set) var pendingNow: Int = 0
    @Published private(set) var lastError: String?
    @Published private(set) var repeatRun: RepeatRun?

    private let center = UNUserNotificationCenter.current()

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode(ProbeRun.self, from: data) {
            run = decoded
        }
        if let data = UserDefaults.standard.data(forKey: Self.repeatKey),
           let decoded = try? JSONDecoder().decode(RepeatRun.self, from: data) {
            repeatRun = decoded
        }
    }

    // MARK: - Measurement B: one repeating trigger

    /// Schedules the single repeating notification that PLAN.md §1.7 actually ships.
    ///
    /// A repeating trigger reuses one identifier, so Notification Center only ever holds its most
    /// recent delivery — that is enough to tell whether it is still firing and still on cadence.
    func scheduleRepeating(intervalMinutes: Int) async {
        await cancelRepeating()

        let now = Date()
        let interval = TimeInterval(intervalMinutes * 60)

        let content = UNMutableNotificationContent()
        content.title = "Voxo probe"
        content.body = "Nhịp lặp \(intervalMinutes) phút"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: Self.repeatIdentifier,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: true)
        )

        do {
            try await center.add(request)
            repeatRun = RepeatRun(startedAt: now, intervalMinutes: intervalMinutes)
            persistRepeat()
        } catch {
            lastError = "Lên lịch lặp lỗi: \(error.localizedDescription)"
        }
        await refresh()
    }

    /// Compares the newest delivery against the slot it should have landed in.
    func collectRepeating() async {
        guard var current = repeatRun else { return }

        let delivered = await center.deliveredNotifications()
        let latest = delivered
            .filter { $0.request.identifier == Self.repeatIdentifier }
            .map(\.date)
            .max()

        current.lastDeliveredAt = latest
        current.stillPending = await center.pendingNotificationRequests()
            .contains { $0.identifier == Self.repeatIdentifier }
        repeatRun = current
        persistRepeat()
    }

    func cancelRepeating() async {
        center.removePendingNotificationRequests(withIdentifiers: [Self.repeatIdentifier])
        center.removeDeliveredNotifications(withIdentifiers: [Self.repeatIdentifier])
        await refresh()
    }

    func clearRepeating() {
        repeatRun = nil
        UserDefaults.standard.removeObject(forKey: Self.repeatKey)
    }

    private func persistRepeat() {
        guard let repeatRun, let data = try? JSONEncoder().encode(repeatRun) else { return }
        UserDefaults.standard.set(data, forKey: Self.repeatKey)
    }

    func refresh() async {
        authorizationStatus = await center.notificationSettings().authorizationStatus
        pendingNow = await center.pendingNotificationRequests()
            .filter { $0.identifier.hasPrefix(Self.identifierPrefix) }
            .count
    }

    func requestAuthorization() async {
        do {
            _ = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            lastError = error.localizedDescription
        }
        await refresh()
    }

    /// Schedules `series * firesPerSeries` notifications: each series is one simulated todo whose
    /// reminders repeat every `intervalMinutes`, and series are staggered by `offsetSeconds` so the
    /// whole set lands inside the observation window.
    func schedule(intervalMinutes: Int, series: Int, firesPerSeries: Int, offsetSeconds: Int) async {
        await cancel()

        let now = Date()
        var fires: [ProbeFire] = []

        for s in 0..<series {
            for k in 0..<firesPerSeries {
                let offset = TimeInterval((s + 1) * offsetSeconds) + TimeInterval(k * intervalMinutes * 60)
                let plannedAt = now.addingTimeInterval(offset)
                let identifier = "\(Self.identifierPrefix)s\(s)-f\(k)"

                let content = UNMutableNotificationContent()
                content.title = "Probe \(s + 1).\(k + 1)"
                content.body = "Hẹn \(Self.timeFormatter.string(from: plannedAt))"
                content.sound = .default
                content.userInfo = ["plannedAt": plannedAt.timeIntervalSince1970]

                let request = UNNotificationRequest(
                    identifier: identifier,
                    content: content,
                    trigger: UNTimeIntervalNotificationTrigger(timeInterval: offset, repeats: false)
                )

                do {
                    try await center.add(request)
                    fires.append(ProbeFire(id: identifier, series: s, index: k, plannedAt: plannedAt))
                } catch {
                    lastError = "Lên lịch \(identifier) lỗi: \(error.localizedDescription)"
                }
            }
        }

        let registered = await center.pendingNotificationRequests()
            .filter { $0.identifier.hasPrefix(Self.identifierPrefix) }
            .count

        run = ProbeRun(
            startedAt: now,
            intervalMinutes: intervalMinutes,
            series: series,
            firesPerSeries: firesPerSeries,
            registeredPending: registered,
            fires: fires.sorted { $0.plannedAt < $1.plannedAt }
        )
        persist()
        await refresh()
    }

    /// Reads delivery timestamps straight out of Notification Center, so the app does not need to
    /// have been running when the notifications fired.
    func collect() async {
        guard var current = run else { return }

        let delivered = await center.deliveredNotifications()
        var byIdentifier: [String: Date] = [:]
        for notification in delivered where notification.request.identifier.hasPrefix(Self.identifierPrefix) {
            byIdentifier[notification.request.identifier] = notification.date
        }

        for index in current.fires.indices {
            if let date = byIdentifier[current.fires[index].id] {
                current.fires[index].deliveredAt = date
            }
        }

        run = current
        persist()
        await refresh()
    }

    func cancel() async {
        let identifiers = await center.pendingNotificationRequests()
            .map(\.identifier)
            .filter { $0.hasPrefix(Self.identifierPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        await refresh()
    }

    func clearRun() {
        run = nil
        UserDefaults.standard.removeObject(forKey: Self.storageKey)
    }

    /// Plain-text report to paste back into the Phase 0 notes.
    var reportText: String {
        guard let run else { return "Chưa có lượt chạy nào." }

        var lines: [String] = [
            "Phase 0 notification probe",
            "Bắt đầu: \(Self.stampFormatter.string(from: run.startedAt))",
            "Chu kỳ: \(run.intervalMinutes) phút · \(run.series) chuỗi x \(run.firesPerSeries) lần = \(run.requested) notification",
            "iOS nhận lịch: \(run.registeredPending)/\(run.requested)",
            "Đã nhận: \(run.deliveredCount) · Đúng giờ (±5 phút): \(run.onTimeCount)"
        ]

        if let rate = run.onTimeRate {
            lines.append(String(format: "Tỉ lệ đúng giờ: %.1f%%", rate * 100))
        }
        if let worst = run.worstDelta {
            lines.append(String(format: "Lệch lớn nhất: %+.0f giây", worst))
        }
        lines.append("")

        for fire in run.fires {
            let planned = Self.timeFormatter.string(from: fire.plannedAt)
            if let delta = fire.delta {
                lines.append(String(format: "%@  hẹn %@  lệch %+.0fs%@", fire.id, planned, delta, fire.onTime ? "" : "  <-- trượt"))
            } else {
                lines.append("\(fire.id)  hẹn \(planned)  chưa nhận")
            }
        }

        return lines.joined(separator: "\n")
    }

    private func persist() {
        guard let run, let data = try? JSONEncoder().encode(run) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }

    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    static let stampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM HH:mm:ss"
        return formatter
    }()
}
