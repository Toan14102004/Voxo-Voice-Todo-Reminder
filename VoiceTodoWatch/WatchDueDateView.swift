//
//  WatchDueDateView.swift
//  VoiceTodoWatch
//
//  Shortcuts rather than a full date picker: on a watch a due date is almost always today or
//  tomorrow, and anything further out is easier to set on the phone. A full `DatePicker` here
//  means a long crown spin for a case that barely happens.
//

import SwiftUI
import VoxoDesign

struct WatchDueDateView: View {
    let current: Date?
    let onPick: (Date?) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var day: Day
    @State private var hour: Int
    @State private var minute: Int

    private enum Day: Hashable {
        case today, tomorrow
    }

    private static let minutes = [0, 15, 30, 45]

    init(current: Date?, onPick: @escaping (Date?) -> Void) {
        self.current = current
        self.onPick = onPick

        let calendar = Calendar.current
        let base = current ?? calendar.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
        _day = State(initialValue: calendar.isDateInTomorrow(base) ? .tomorrow : .today)
        _hour = State(initialValue: calendar.component(.hour, from: base))
        // Snap onto the quarter-hour grid the picker offers, so reopening never shifts the value.
        let storedMinute = calendar.component(.minute, from: base)
        _minute = State(initialValue: Self.minutes.min(by: {
            abs($0 - storedMinute) < abs($1 - storedMinute)
        }) ?? 0)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: VoxoSpacing.s) {
                Picker("Day", selection: $day) {
                    Text("Today").tag(Day.today)
                    Text("Tomorrow").tag(Day.tomorrow)
                }
                .pickerStyle(.navigationLink)

                HStack(spacing: VoxoSpacing.xs) {
                    Picker("Hour", selection: $hour) {
                        ForEach(0..<24, id: \.self) { value in
                            Text(verbatim: String(format: "%02d", value)).tag(value)
                        }
                    }
                    Picker("Minute", selection: $minute) {
                        ForEach(Self.minutes, id: \.self) { value in
                            Text(verbatim: String(format: "%02d", value)).tag(value)
                        }
                    }
                }
                .frame(height: 76)

                Button("Save") {
                    onPick(resolved())
                    dismiss()
                }
                .buttonStyle(VoxoPrimaryButtonStyle())

                if current != nil {
                    Button("Clear") {
                        onPick(nil)
                        dismiss()
                    }
                    .buttonStyle(VoxoSecondaryButtonStyle())
                }
            }
            .padding(.horizontal, VoxoSpacing.screenMargin)
        }
        .navigationTitle("Due")
    }

    private func resolved() -> Date? {
        let calendar = Calendar.current
        let base = day == .tomorrow
            ? calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
            : Date()
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: base)
    }
}
