//
//  ReminderPlan.swift
//  VoxoShared
//

import Foundation

/// One notification the app should have scheduled.
///
/// Every plan repeats forever; the app removes it when the underlying todos are gone. That is the
/// whole point of PLAN.md §1.7 — one pending slot instead of one per reminder occurrence.
public struct ReminderPlan: Equatable, Identifiable, Sendable {
    public enum Kind: Equatable, Sendable {
        /// Covers every todo on the shared cycle.
        case shared(todoCount: Int)
        /// One todo that set its own `intervalOverride`.
        case single
    }

    public let id: String
    public let kind: Kind
    /// The todo the notification names, and the one its "Done" action completes.
    public let todoId: UUID
    public let title: String
    public let body: String
    public let intervalMinutes: Int

    public init(id: String, kind: Kind, todoId: UUID, title: String, body: String, intervalMinutes: Int) {
        self.id = id
        self.kind = kind
        self.todoId = todoId
        self.title = title
        self.body = body
        self.intervalMinutes = intervalMinutes
    }

    public static let identifierPrefix = "voxo-reminder-"
    public static let sharedIdentifier = identifierPrefix + "shared"

    public static func identifier(for todoId: UUID) -> String {
        identifierPrefix + todoId.uuidString
    }
}
