//
//  TodoListDTO.swift
//  VoxoShared
//

import Foundation

/// A named, colour-coded list of todos (PLAN.md §4, entity `TodoList`).
public struct TodoListDTO: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var name: String
    /// "RRGGBB", no leading hash — the label colour from the design.
    public var colorHex: String
    /// SF Symbol name.
    public var icon: String
    public var createdAt: Date
    public var updatedAt: Date
    public var deletedAt: Date?

    public init(
        id: UUID = UUID(),
        name: String,
        colorHex: String,
        icon: String = "folder",
        createdAt: Date,
        updatedAt: Date,
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.icon = icon
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }

    public var isDeleted: Bool { deletedAt != nil }

    public static let maxNameLength = 60

    /// The palette and icons offered when creating a list, taken from the design's examples
    /// (Cá nhân, Công việc, Mua sắm, Sức khỏe, Học tập).
    public static let paletteHex = ["1E6FD0", "F59E0B", "16A34A", "EC4899", "8B5CF6", "EF4444"]
    public static let iconChoices = ["house", "briefcase", "cart", "dumbbell", "book", "star"]

    public static func sanitize(name: String) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return String(trimmed.prefix(maxNameLength))
    }
}
