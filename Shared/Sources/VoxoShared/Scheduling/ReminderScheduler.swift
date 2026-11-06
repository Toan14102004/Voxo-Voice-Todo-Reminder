//
//  ReminderScheduler.swift
//  VoxoShared
//
//  PLAN.md §5, rewritten for the aggregated reminders decided in §1.7.
//
//  Pure: no Core Data, no UNUserNotificationCenter, no clock of its own. Input is a snapshot,
//  output is a list — which is what makes every rule here unit-testable.
//

import Foundation

public enum ReminderScheduler {
    /// Builds the complete set of notifications that should exist right now.
    ///
    /// - Todos on the shared cycle collapse into **one** repeating notification naming the oldest
    ///   of them plus a count.
    /// - Each todo with `intervalOverride > 0` gets its own repeating notification.
    ///
    /// Total slots used: `1 + number of todos with a custom cycle`, instead of
    /// `todos × (horizon / cycle)` under the original per-todo design.
    public static func plan(
        todos: [TodoDTO],
        globalIntervalMinutes: Int = SyncSettings.defaultIntervalMinutes
    ) -> [ReminderPlan] {
        // Rule 1 (unchanged from §5): only unfinished, undeleted todos are ever reminded about.
        let active = todos
            .filter(\.isActive)
            .sorted { lhs, rhs in
                lhs.createdAt == rhs.createdAt
                    ? lhs.id.uuidString < rhs.id.uuidString
                    : lhs.createdAt < rhs.createdAt
            }

        guard !active.isEmpty else { return [] }

        let custom = active.filter { $0.intervalOverride > 0 }
        let onSharedCycle = active.filter { $0.intervalOverride == 0 }

        var plans: [ReminderPlan] = []

        if let oldest = onSharedCycle.first {
            plans.append(
                ReminderPlan(
                    id: ReminderPlan.sharedIdentifier,
                    kind: .shared(todoCount: onSharedCycle.count),
                    todoId: oldest.id,
                    title: "Voxo",
                    body: body(naming: oldest, outOf: onSharedCycle.count),
                    intervalMinutes: globalIntervalMinutes
                )
            )
        }

        for todo in custom {
            plans.append(
                ReminderPlan(
                    id: ReminderPlan.identifier(for: todo.id),
                    kind: .single,
                    todoId: todo.id,
                    title: "Voxo",
                    body: todo.title,
                    intervalMinutes: Int(todo.intervalOverride)
                )
            )
        }

        return plans
    }

    /// "Call mum" on its own, or "Call mum — and 4 others" when more are waiting (PLAN.md §1.7).
    static func body(naming todo: TodoDTO, outOf count: Int) -> String {
        guard count > 1 else { return todo.title }
        let others = count - 1
        return "\(todo.title) — and \(others) other\(others == 1 ? "" : "s")"
    }
}
