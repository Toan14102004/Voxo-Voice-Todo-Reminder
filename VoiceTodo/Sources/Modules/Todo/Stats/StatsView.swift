//
//  StatsView.swift
//  VoiceTodo
//
//  Design: frame "VI / 7 Thống kê".
//

import SwiftUI
import VoxoDesign
import VoxoShared

struct StatsView: View {
    @EnvironmentObject private var store: TodoStore
    @StateObject private var viewModel = ViewModel()
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.locale) private var locale

    var body: some View {
        let stats = viewModel.stats(store: store)

        ScrollView {
            VStack(alignment: .leading, spacing: VoxoSpacing.l) {
                header
                summary(stats)
                dailyChart(stats)
                byList(stats)
            }
            .padding(.horizontal, VoxoSpacing.screenMargin)
            .padding(.top, VoxoSpacing.l)
            .padding(.bottom, VoxoSpacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(VoxoColor.background)
        .onAppear { viewModel.calendar = settings.calendar }
        .onChange(of: settings.weekStart) { _ in viewModel.calendar = settings.calendar }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Stats")
                .font(VoxoFont.display)
                .foregroundStyle(VoxoColor.textPrimary)

            Spacer()

            Menu {
                Picker("Range", selection: $viewModel.period) {
                    ForEach(Period.allCases) { period in
                        Text(period.title).tag(period)
                    }
                }
            } label: {
                HStack(spacing: VoxoSpacing.xs) {
                    Text(viewModel.period.title)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                }
                .font(VoxoFont.headline)
                .foregroundStyle(VoxoColor.primary)
            }
        }
    }

    private func summary(_ stats: WeekStats) -> some View {
        HStack(spacing: VoxoSpacing.m) {
            VoxoStatCard(
                icon: VoxoIcon.streak,
                value: String(format: "%lld days".localizedString, stats.streak),
                label: "Streak",
                tint: VoxoColor.priorityMedium
            )

            VoxoStatCard(
                icon: VoxoIcon.rate,
                value: stats.completionRate.formatted(.percent.precision(.fractionLength(0))),
                label: "Completion rate",
                tint: VoxoColor.success
            )
        }
    }

    private func dailyChart(_ stats: WeekStats) -> some View {
        VoxoCard {
            VStack(alignment: .leading, spacing: VoxoSpacing.m) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tasks completed per day")
                        .font(VoxoFont.headline)
                        .foregroundStyle(VoxoColor.textPrimary)

                    (Text("\(stats.completedTotal) tasks") + Text(verbatim: " · ")
                        + Text(deltaKey(stats.deltaVsPreviousWeek)))
                        .font(VoxoFont.caption)
                        .foregroundStyle(
                            stats.deltaVsPreviousWeek >= 0 ? VoxoColor.success : VoxoColor.textSecondary
                        )
                }

                VoxoBarChart(entries: entries(stats))
            }
            .padding(.vertical, VoxoSpacing.l)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func byList(_ stats: WeekStats) -> some View {
        if !stats.byList.isEmpty {
            VoxoCard {
                VStack(alignment: .leading, spacing: VoxoSpacing.l) {
                    Text("By list")
                        .font(VoxoFont.headline)
                        .foregroundStyle(VoxoColor.textPrimary)

                    ForEach(stats.byList) { list in
                        VoxoListProgressRow(
                            icon: list.icon,
                            name: list.name,
                            done: list.done,
                            total: list.total,
                            tint: Color(hexString: list.colorHex)
                        )
                    }
                }
                .padding(.vertical, VoxoSpacing.l)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func entries(_ stats: WeekStats) -> [VoxoBarChartEntry] {
        let labels = viewModel.weekdayLabels(locale: locale)
        let highlighted = viewModel.highlightedIndex
        return stats.perDay.indices.map { index in
            VoxoBarChartEntry(
                id: index,
                label: labels[index],
                value: stats.perDay[index],
                isHighlighted: index == highlighted
            )
        }
    }

    private func deltaKey(_ delta: Int) -> LocalizedStringKey {
        switch delta {
        case 0: "Same as last week"
        case 1...: "+\(delta) vs last week"
        default: "\(delta) vs last week"
        }
    }
}
