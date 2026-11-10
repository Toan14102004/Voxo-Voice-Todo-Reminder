//
//  StatsViewModel.swift
//  VoiceTodo
//

import Foundation
import SwiftUI
import VoxoDesign
import VoxoShared

extension StatsView {
    /// Which week the screen is reporting on.
    ///
    /// Both options are weeks on purpose: every figure on the screen — the seven bars, the
    /// "so với tuần trước" comparison, the per-list split — is defined against a week, so a month
    /// range would make the chart mean something other than its own title.
    enum Period: String, CaseIterable, Identifiable {
        case thisWeek
        case lastWeek

        var id: String { rawValue }

        var title: LocalizedStringKey {
            switch self {
            case .thisWeek: "This week"
            case .lastWeek: "Last week"
            }
        }

        var weeksAgo: Int {
            switch self {
            case .thisWeek: 0
            case .lastWeek: 1
            }
        }
    }

    @MainActor
    final class ViewModel: ObservableObject {
        @Published var period: Period = .thisWeek

        /// From Settings → "Tuần bắt đầu từ", so the seven columns line up with the Calendar
        /// tab's day strip.
        @Published var calendar: Calendar
        private let now: Date

        init(calendar: Calendar = .current, now: Date = Date()) {
            self.calendar = calendar
            self.now = now
        }

        private var weekStart: Date {
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
            let thisWeek = calendar.date(from: components) ?? calendar.startOfDay(for: now)
            return calendar.date(byAdding: .weekOfYear, value: -period.weeksAgo, to: thisWeek) ?? thisWeek
        }

        private var week: [Date] {
            (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }
        }

        /// Narrow, not abbreviated: Vietnamese gives "T2" rather than "Thứ 2", which is what the
        /// design's chart shows and what fits seven columns.
        func weekdayLabels(locale: Locale) -> [String] {
            week.map { $0.formatted(.dateTime.weekday(.narrow).locale(locale)) }
        }

        /// The column the chart highlights: today, when today is inside the week on screen.
        var highlightedIndex: Int? {
            week.firstIndex { calendar.isDate($0, inSameDayAs: now) }
        }

        func stats(store: TodoStore) -> WeekStats {
            StatsCalculator.stats(
                todos: store.active + store.completed,
                lists: store.lists,
                weekStart: weekStart,
                now: now,
                calendar: calendar
            )
        }
    }
}
