//
//  VoxoTabBar.swift
//  VoxoDesign
//
//  DS / Components: Tab bar 390×88, Day 44×68, FAB 60×60.
//

import SwiftUI

/// The four destinations from the navigation graph (PLAN.md §7).
public enum VoxoTab: String, CaseIterable, Identifiable, Sendable {
    case today, calendar, lists, stats

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .today: VoxoIcon.Tab.today
        case .calendar: VoxoIcon.Tab.calendar
        case .lists: VoxoIcon.Tab.lists
        case .stats: VoxoIcon.Tab.stats
        }
    }

    public var title: LocalizedStringKey {
        switch self {
        case .today: "Today"
        case .calendar: "Calendar"
        case .lists: "Lists"
        case .stats: "Stats"
        }
    }
}

public struct VoxoTabBar: View {
    @Binding private var selection: VoxoTab

    public init(selection: Binding<VoxoTab>) {
        _selection = selection
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(VoxoTab.allCases) { tab in
                Button {
                    selection = tab
                } label: {
                    VStack(spacing: VoxoSpacing.xs) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 24, weight: selection == tab ? .semibold : .regular))
                        Text(tab.title)
                            .font(VoxoFont.overline)
                    }
                    .foregroundStyle(selection == tab ? VoxoColor.primary : VoxoColor.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: VoxoHitTarget.minimum)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == tab ? [.isSelected] : [])
            }
        }
        .padding(.top, VoxoSpacing.s)
        .background(VoxoColor.surface)
        .overlay(alignment: .top) {
            Rectangle().fill(VoxoColor.separator).frame(height: 1)
        }
    }
}

/// One day in the Calendar strip: weekday above, date below, filled when selected.
public struct VoxoDayCell: View {
    private let weekday: String
    private let day: String
    private let isSelected: Bool
    private let action: () -> Void

    public init(weekday: String, day: String, isSelected: Bool, action: @escaping () -> Void) {
        self.weekday = weekday
        self.day = day
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            VStack(spacing: VoxoSpacing.xs) {
                Text(verbatim: weekday)
                    .font(VoxoFont.caption)
                Text(verbatim: day)
                    .font(VoxoFont.headline)
            }
            .foregroundStyle(isSelected ? VoxoColor.textOnAccent : VoxoColor.textSecondary)
            .frame(width: 44, height: 68)
            .background(isSelected ? VoxoColor.primary : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: VoxoRadius.taskRow, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

/// Floating add button. DS / Rules: sits above everything, 14pt clear of the tab bar,
/// 30% blue shadow.
public struct VoxoFAB: View {
    private let action: () -> Void

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: VoxoIcon.add)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(VoxoColor.textOnAccent)
                .frame(width: VoxoFABMetrics.size, height: VoxoFABMetrics.size)
                .background(VoxoColor.primary)
                .clipShape(Circle())
                .shadow(
                    color: VoxoColor.primary.opacity(VoxoFABMetrics.shadowOpacity),
                    radius: VoxoFABMetrics.shadowRadius,
                    y: 6
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add task")
    }
}
