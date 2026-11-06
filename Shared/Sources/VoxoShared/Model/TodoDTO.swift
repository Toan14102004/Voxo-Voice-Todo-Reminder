//
//  TodoDTO.swift
//  VoxoShared
//

import Foundation

/// Transport and merge representation of a todo — the shape that crosses WCSession.
///
/// Mirrors the `Todo` entity in PLAN.md §4 one-for-one so merging never needs a managed object.
public struct TodoDTO: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var title: String
    public var isDone: Bool
    public var createdAt: Date
    public var updatedAt: Date
    public var completedAt: Date?
    public var deletedAt: Date?
    /// Minutes. Zero means "use the shared interval" (PLAN.md §4).
    public var intervalOverride: Int32
    public var nextRemindAt: Date?
    public var lastRemindedAt: Date?
    public var originDevice: DeviceRole

    public init(
        id: UUID = UUID(),
        title: String,
        isDone: Bool = false,
        createdAt: Date,
        updatedAt: Date,
        completedAt: Date? = nil,
        deletedAt: Date? = nil,
        intervalOverride: Int32 = 0,
        nextRemindAt: Date? = nil,
        lastRemindedAt: Date? = nil,
        originDevice: DeviceRole
    ) {
        self.id = id
        self.title = title
        self.isDone = isDone
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.completedAt = completedAt
        self.deletedAt = deletedAt
        self.intervalOverride = intervalOverride
        self.nextRemindAt = nextRemindAt
        self.lastRemindedAt = lastRemindedAt
        self.originDevice = originDevice
    }

    /// A tombstoned todo is deleted regardless of `isDone` (PLAN.md §6).
    public var isDeleted: Bool { deletedAt != nil }

    /// Only these are eligible for reminders (PLAN.md §5 rule 1).
    public var isActive: Bool { !isDone && !isDeleted }
}

public extension TodoDTO {
    /// Title rules from PLAN.md §4: non-empty after trimming, 200 characters max.
    static let maxTitleLength = 200

    static func sanitize(title: String) -> String? {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return String(trimmed.prefix(maxTitleLength))
    }
}
