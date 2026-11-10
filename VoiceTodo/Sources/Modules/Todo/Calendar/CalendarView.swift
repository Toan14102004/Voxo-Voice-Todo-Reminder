//
//  CalendarView.swift
//  VoiceTodo
//
//  Design: frame "VI / 6 Lịch".
//

import SwiftUI
import VoxoDesign
import VoxoShared

struct CalendarView: View {
    @EnvironmentObject private var store: TodoStore
    @StateObject private var viewModel = ViewModel()
    @EnvironmentObject private var settings: AppSettings
    @Navigation private var navigation
    @Environment(\.locale) private var locale

    var body: some View {
        VStack(alignment: .leading, spacing: VoxoSpacing.l) {
            header
            weekStrip
            dayHeading
            timeline
        }
        .padding(.top, VoxoSpacing.l)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(VoxoColor.background)
        .onAppear { viewModel.calendar = settings.calendar }
        .onChange(of: settings.weekStart) { _ in viewModel.calendar = settings.calendar }
    }

    private var header: some View {
        HStack {
            Text(verbatim: viewModel.monthTitle(locale))
                .font(VoxoFont.display)
                .foregroundStyle(VoxoColor.textPrimary)

            Spacer()

            HStack(spacing: VoxoSpacing.l) {
                Button { viewModel.previousWeek() } label: {
                    Image(systemName: "chevron.left")
                }
                .accessibilityLabel("Previous week")

                Button { viewModel.nextWeek() } label: {
                    Image(systemName: "chevron.right")
                }
                .accessibilityLabel("Next week")
            }
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(VoxoColor.primary)
        }
        .padding(.horizontal, VoxoSpacing.screenMargin)
    }

    private var weekStrip: some View {
        HStack(spacing: VoxoSpacing.xs) {
            ForEach(viewModel.week, id: \.self) { day in
                VoxoDayCell(
                    weekday: viewModel.weekdayLabel(day, locale: locale),
                    day: viewModel.dayLabel(day),
                    isSelected: viewModel.isSelected(day)
                ) {
                    viewModel.select(day)
                }
                .frame(maxWidth: .infinity)
                .background(
                    viewModel.isSelected(day) ? Color.clear : VoxoColor.surface,
                    in: RoundedRectangle(cornerRadius: VoxoRadius.taskRow, style: .continuous)
                )
            }
        }
        .padding(.horizontal, VoxoSpacing.screenMargin)
    }

    private var dayHeading: some View {
        // Two Texts: the date is user data, the count half is a localizable key.
        (Text(verbatim: viewModel.dayLabelLong(locale)) + Text(verbatim: " · ")
            + Text("\(todosForDay.count) tasks"))
            .font(VoxoFont.headline)
            .foregroundStyle(VoxoColor.textPrimary)
            .padding(.horizontal, VoxoSpacing.screenMargin)
    }

    @ViewBuilder
    private var timeline: some View {
        if todosForDay.isEmpty {
            VoxoEmptyState(
                icon: VoxoIcon.Tab.calendar,
                title: "Nothing scheduled",
                message: "Tasks with a time on this day will show up here."
            )
            .frame(maxHeight: .infinity)
        } else {
            ScrollView {
                VStack(spacing: VoxoSpacing.m) {
                    ForEach(todosForDay) { todo in
                        row(todo)
                    }

                    // Stated in the design; the gesture itself is not built yet.
                    Text("Drag to reschedule — coming later")
                        .font(VoxoFont.caption)
                        .foregroundStyle(VoxoColor.textMuted)
                        .padding(.top, VoxoSpacing.s)
                }
                .padding(.horizontal, VoxoSpacing.screenMargin)
                .padding(.bottom, VoxoSpacing.xl)
            }
        }
    }

    private func row(_ todo: TodoDTO) -> some View {
        HStack(alignment: .top, spacing: VoxoSpacing.m) {
            Text(verbatim: viewModel.timeLabel(todo, locale: locale))
                .font(VoxoFont.body)
                .foregroundStyle(VoxoColor.textSecondary)
                .frame(width: 56, alignment: .leading)
                .padding(.top, VoxoSpacing.m)

            VoxoEventCard(
                title: todo.title,
                detail: viewModel.detail(for: todo, store: store, locale: locale),
                tint: viewModel.tint(for: todo, store: store)
            )
            .onTapGesture {
                navigation.push(TodayView.Coordinator.Navigation.detail(todo.id))
            }
        }
    }

    private var todosForDay: [TodoDTO] {
        viewModel.todos(on: viewModel.selectedDay, store: store)
    }
}
