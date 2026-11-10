//
//  StatsCalculator.swift
//  VoxoShared
//

import Foundation

/// Everything the Stats tab reports for one week.
public struct WeekStats: Equatable, Sendable {
    /// Consecutive days, counting back, with at least one completion.
    public var streak: Int
    /// Finished ÷ everything that belonged to the week, 0…1.
    public var completionRate: Double
    /// Completions on each of the seven days, Monday first.
    public var perDay: [Int]
    public var completedTotal: Int
    /// `completedTotal` minus the same figure for the preceding week.
    public var deltaVsPreviousWeek: Int
    public var byList: [ListStats]

    public init(
        streak: Int = 0,
        completionRate: Double = 0,
        perDay: [Int] = Array(repeating: 0, count: 7),
        completedTotal: Int = 0,
        deltaVsPreviousWeek: Int = 0,
        byList: [ListStats] = []
    ) {
        self.streak = streak
        self.completionRate = completionRate
        self.perDay = perDay
        self.completedTotal = completedTotal
        self.deltaVsPreviousWeek = deltaVsPreviousWeek
        self.byList = byList
    }
}

/// One list's share of the week.
public struct ListStats: Equatable, Identifiable, Sendable {
    public let id: UUID
    public let name: String
    public let icon: String
    public let colorHex: String
    public let done: Int
    public let total: Int

    public init(id: UUID, name: String, icon: String, colorHex: String, done: Int, total: Int) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.done = done
        self.total = total
    }
}

/// Pure week-over-week arithmetic for the Stats tab. No UI, no Core Data — all of it is a
/// function of the todos handed in (PLAN.md §2).
public enum StatsCalculator {
    /// A task **belongs** to a week if it was completed inside it, or if it is still open and was
    /// created inside it. Work carried over from an earlier week is not counted against this one;
    /// otherwise one forgotten task would hold the rate down week after week.
    public static func stats(
        todos: [TodoDTO],
        lists: [TodoListDTO],
        weekStart: Date,
        now: Date,
        calendar: Calendar
    ) -> WeekStats {
        guard let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else {
            return WeekStats()
        }
        let days = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }

        let completed = todos.filter { wasCompleted($0, from: weekStart, to: weekEnd) }
        let open = todos.filter { $0.isActive && $0.createdAt >= weekStart && $0.createdAt < weekEnd }

        var stats = WeekStats()
        stats.completedTotal = completed.count

        let belonging = completed.count + open.count
        stats.completionRate = belonging > 0 ? Double(completed.count) / Double(belonging) : 0

        stats.perDay = days.map { day in
            completed.filter { calendar.isDate($0.completedAt ?? .distantPast, inSameDayAs: day) }.count
        }

        if let previousStart = calendar.date(byAdding: .weekOfYear, value: -1, to: weekStart),
           let previousEnd = calendar.date(byAdding: .day, value: 7, to: previousStart) {
            let previous = todos.filter { wasCompleted($0, from: previousStart, to: previousEnd) }.count
            stats.deltaVsPreviousWeek = stats.completedTotal - previous
        }

        stats.streak = streak(
            todos: todos,
            upTo: min(days.last ?? weekStart, now),
            calendar: calendar
        )

        stats.byList = lists.compactMap { list in
            let done = completed.filter { $0.listId == list.id }.count
            let remaining = open.filter { $0.listId == list.id }.count
            guard done + remaining > 0 else { return nil }
            return ListStats(
                id: list.id,
                name: list.name,
                icon: list.icon,
                colorHex: list.colorHex,
                done: done,
                total: done + remaining
            )
        }

        return stats
    }

    /// Counting starts at `day` and steps back one day first when nothing was finished on it —
    /// otherwise the streak would read zero every morning until the first task is ticked.
    public static func streak(todos: [TodoDTO], upTo day: Date, calendar: Calendar) -> Int {
        let completionDays = Set(todos.compactMap { todo in
            todo.completedAt.map { calendar.startOfDay(for: $0) }
        })
        guard !completionDays.isEmpty else { return 0 }

        var cursor = calendar.startOfDay(for: day)
        if !completionDays.contains(cursor) {
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { return 0 }
            cursor = previous
        }

        var count = 0
        while completionDays.contains(cursor) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return count
    }

    private static func wasCompleted(_ todo: TodoDTO, from start: Date, to end: Date) -> Bool {
        guard let completedAt = todo.completedAt else { return false }
        return completedAt >= start && completedAt < end
    }
}
