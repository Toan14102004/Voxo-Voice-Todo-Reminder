//
//  MergeService.swift
//  VoxoShared
//

import Foundation

/// What a merge concluded for one todo.
public enum MergeOutcome: Equatable {
    /// No local copy existed; insert the incoming one.
    case insert(TodoDTO)
    /// The incoming version wins; overwrite the local copy.
    case update(TodoDTO)
    /// The local copy wins; write nothing.
    case keepLocal
}

/// Conflict resolution from PLAN.md §6.
///
/// Pure value logic, no Core Data, so every rule is unit-testable.
public struct MergeService: Sendable {
    /// Which side this device is. Used only to break `updatedAt` ties, where the phone wins.
    public let device: DeviceRole

    public init(device: DeviceRole) {
        self.device = device
    }

    public func merge(local: TodoDTO?, incoming: TodoDTO) -> MergeOutcome {
        guard let local else { return .insert(incoming) }

        // A tombstone always wins in v1: there is no restore flow, so a delete can never be
        // undone by a later edit arriving from the other device.
        if local.isDeleted, !incoming.isDeleted { return .keepLocal }
        if incoming.isDeleted, !local.isDeleted { return .update(incoming) }
        if local.isDeleted, incoming.isDeleted {
            // Both deleted: keep the earlier tombstone so the 30-day purge clock does not restart.
            let localDeletedAt = local.deletedAt ?? local.updatedAt
            let incomingDeletedAt = incoming.deletedAt ?? incoming.updatedAt
            return incomingDeletedAt < localDeletedAt ? .update(incoming) : .keepLocal
        }

        if incoming.updatedAt > local.updatedAt { return .update(incoming) }
        if incoming.updatedAt < local.updatedAt { return .keepLocal }

        // Equal timestamps: the phone's version wins (PLAN.md §6).
        return device == .watch ? .update(incoming) : .keepLocal
    }

    /// True once a tombstone is old enough to drop (PLAN.md §6: 30 days).
    public func isPurgeable(_ todo: TodoDTO, olderThan maxAge: TimeInterval, now: Date) -> Bool {
        guard let deletedAt = todo.deletedAt else { return false }
        return now.timeIntervalSince(deletedAt) >= maxAge
    }

    /// 30 days, in seconds.
    public static let tombstoneRetention: TimeInterval = 30 * 24 * 60 * 60
}
