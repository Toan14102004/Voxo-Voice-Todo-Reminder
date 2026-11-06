//
//  SyncMessage.swift
//  VoxoShared
//

import Foundation

/// Everything that crosses WCSession (PLAN.md §6).
///
/// Phase 5 wires these to `transferUserInfo` / `updateApplicationContext`; the shapes live here so
/// both apps and the tests agree on them.
public enum SyncMessage: Codable, Equatable, Sendable {
    /// Watch -> phone: one queued change.
    case op(SyncOpDTO)
    /// Phone -> watch: acknowledgement so the outbox can drop those ops.
    case ack([UUID])
    /// Phone -> watch: the full current state of a changed todo.
    case todo(TodoDTO)

    public func encoded() throws -> [String: Any] {
        let data = try VoxoCoder.encoder.encode(self)
        return ["payload": data]
    }

    public static func decode(from userInfo: [String: Any]) throws -> SyncMessage? {
        guard let data = userInfo["payload"] as? Data else { return nil }
        return try VoxoCoder.decoder.decode(SyncMessage.self, from: data)
    }
}

/// Shared settings pushed with `updateApplicationContext` (PLAN.md §6).
public struct SyncSettings: Codable, Equatable, Sendable {
    public var globalIntervalMinutes: Int

    public init(globalIntervalMinutes: Int) {
        self.globalIntervalMinutes = globalIntervalMinutes
    }

    /// PLAN.md §4: anything outside this list is rejected in v1.
    public static let allowedIntervals: [Int] = [60, 120, 180, 240, 360, 480, 720, 1440]
    public static let defaultIntervalMinutes = 60

    public static func isValid(_ minutes: Int) -> Bool { allowedIntervals.contains(minutes) }
}
