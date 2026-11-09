//
//  TodaySection.swift
//  VoiceTodo
//

import Foundation
import SwiftUI
import VoxoShared

/// The three groups on the Today screen (design "VI / 2 Hôm nay").
enum TodaySection: String, CaseIterable, Identifiable {
    case overdue
    case today
    case done

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .overdue: "Overdue"
        case .today: "Today"
        case .done: "Done"
        }
    }

    /// Overdue is the only group the design colours; the rest stay neutral.
    var isAlarming: Bool { self == .overdue }

    /// Buckets the list exactly as the design shows it.
    static func group(_ todos: [TodoDTO], completed: [TodoDTO], now: Date) -> [TodaySection: [TodoDTO]] {
        let startOfTomorrow = Calendar.current.startOfDay(for: now.addingTimeInterval(86_400))

        var result: [TodaySection: [TodoDTO]] = [:]
        result[.overdue] = todos.filter { todo in
            guard let dueAt = todo.dueAt else { return false }
            return dueAt < now
        }
        result[.today] = todos.filter { todo in
            guard let dueAt = todo.dueAt else { return true }   // undated work belongs to today
            return dueAt >= now && dueAt < startOfTomorrow
        }
        result[.done] = completed
        return result
    }
}
