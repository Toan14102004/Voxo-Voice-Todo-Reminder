//
//  CalendarViewModel.swift
//  VoiceTodo
//

import Foundation
import SwiftUI
import VoxoDesign
import VoxoShared

extension CalendarView {
    @MainActor
    final class ViewModel: ObservableObject {
        @Published private(set) var selectedDay: Date
        @Published private(set) var weekStart: Date

        /// From Settings → "Tuần bắt đầu từ"; the design's strip starts on Monday, the default.
        /// Published, and the visible week is rebuilt on change, because the preference can be
        /// switched while this screen is still alive.
        @Published var calendar: Calendar {
            didSet { weekStart = Self.startOfWeek(for: selectedDay, calendar: calendar) }
        }

        init(calendar: Calendar = .current, now: Date = Date()) {
            self.calendar = calendar

            let today = calendar.startOfDay(for: now)
            selectedDay = today
            weekStart = Self.startOfWeek(for: today, calendar: calendar)
        }

        private static func startOfWeek(for day: Date, calendar: Calendar) -> Date {
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: day)
            return calendar.date(from: components) ?? day
        }

        var week: [Date] {
            (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }
        }

        // MARK: - Labels
        //
        // The locale comes from the view's environment, not `Locale.current`: dates would
        // otherwise follow the system language while the rest of the screen follows the app's.

        /// "Tháng 11 năm 2026" — Vietnamese month names are lower case, so only the first
        /// character is raised.
        func monthTitle(_ locale: Locale) -> String {
            let raw = selectedDay.formatted(.dateTime.month(.wide).year().locale(locale))
            guard let first = raw.first else { return raw }
            return String(first).uppercased(with: locale) + raw.dropFirst()
        }

        /// Narrow, not abbreviated: Vietnamese gives "T2" rather than "Thứ 2", which is what the
        /// design's day strip shows and what fits a 44pt cell.
        func weekdayLabel(_ day: Date, locale: Locale) -> String {
            day.formatted(.dateTime.weekday(.narrow).locale(locale))
        }

        func dayLabel(_ day: Date) -> String {
            "\(calendar.component(.day, from: day))"
        }

        /// "Thứ Bảy, 9/11" — the task count is appended by the view so it stays localizable.
        func dayLabelLong(_ locale: Locale) -> String {
            selectedDay.formatted(
                .dateTime.weekday(.wide).day().month(.defaultDigits).locale(locale)
            )
        }

        /// 24-hour: matches the design, and short enough not to wrap in the time gutter.
        func timeLabel(_ todo: TodoDTO, locale: Locale) -> String {
            guard let dueAt = todo.dueAt else { return "--:--" }
            return dueAt.formatted(
                .dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits).locale(locale)
            )
        }

        /// "07:00 · Sức khỏe".
        func detail(for todo: TodoDTO, store: TodoStore, locale: Locale) -> String {
            var parts: [String] = [timeLabel(todo, locale: locale)]
            if let listId = todo.listId, let list = store.list(id: listId) {
                parts.append(list.name)
            }
            return parts.joined(separator: " · ")
        }

        func tint(for todo: TodoDTO, store: TodoStore) -> Color {
            guard let listId = todo.listId, let list = store.list(id: listId) else {
                return VoxoColor.primary
            }
            return Color(hexString: list.colorHex)
        }

        // MARK: - Selection

        func isSelected(_ day: Date) -> Bool {
            calendar.isDate(day, inSameDayAs: selectedDay)
        }

        func select(_ day: Date) {
            selectedDay = day
        }

        func previousWeek() {
            shiftWeek(by: -1)
        }

        func nextWeek() {
            shiftWeek(by: 1)
        }

        private func shiftWeek(by weeks: Int) {
            guard let newStart = calendar.date(byAdding: .weekOfYear, value: weeks, to: weekStart),
                  let newSelection = calendar.date(byAdding: .weekOfYear, value: weeks, to: selectedDay)
            else { return }
            weekStart = newStart
            // Keep the same weekday selected, so stepping weeks does not jump the cursor around.
            selectedDay = newSelection
        }

        // MARK: - Content

        /// Only dated tasks appear: the calendar is about *when*, and undated work has no slot.
        func todos(on day: Date, store: TodoStore) -> [TodoDTO] {
            (store.active + store.completed)
                .filter { todo in
                    guard let dueAt = todo.dueAt else { return false }
                    return calendar.isDate(dueAt, inSameDayAs: day)
                }
                .sorted { ($0.dueAt ?? .distantPast) < ($1.dueAt ?? .distantPast) }
        }
    }
}
