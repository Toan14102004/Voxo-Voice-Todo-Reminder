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
                StatsView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(VoxoColor.background)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VoxoTabBar(selection: $tab)
        }
    }
}
