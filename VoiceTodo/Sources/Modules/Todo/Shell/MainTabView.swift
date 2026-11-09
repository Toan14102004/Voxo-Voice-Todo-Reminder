//
//  MainTabView.swift
//  VoiceTodo
//
//  The four-destination shell from the navigation graph (PLAN.md §7).
//

import SwiftUI
import VoxoDesign
import VoxoShared

struct MainTabView: View {
    @EnvironmentObject private var store: TodoStore
    @State private var tab: VoxoTab = Self.initialTab

    private static var initialTab: VoxoTab {
        #if DEBUG
            // -tab today|calendar|lists|stats opens straight onto a tab, for screenshots.
            let args = ProcessInfo.processInfo.arguments
            if let i = args.firstIndex(of: "-tab"), i + 1 < args.count,
               let requested = VoxoTab(rawValue: args[i + 1]) {
                return requested
            }
        #endif
        return .today
    }

    var body: some View {
        VStack(spacing: 0) {
            switch tab {
            case .today:
                TodayView()
            case .calendar:
                CalendarView()
            case .lists:
                ListsView()
            case .stats:
                ComingSoonTab(
                    icon: VoxoIcon.Tab.stats,
                    title: "Stats",
                    message: "Streaks and weekly totals will show up here."
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(VoxoColor.background)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VoxoTabBar(selection: $tab)
        }
    }
}

/// Placeholder for a tab whose screen is not written yet.
private struct ComingSoonTab: View {
    let icon: String
    let title: LocalizedStringKey
    let message: LocalizedStringKey

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(VoxoFont.display)
                    .foregroundStyle(VoxoColor.textPrimary)
                Spacer()
            }
            .padding(.horizontal, VoxoSpacing.screenMargin)
            .padding(.top, VoxoSpacing.l)

            Spacer()

            VoxoEmptyState(icon: icon, title: "Not built yet", message: message)

            Spacer()
        }
    }
}
