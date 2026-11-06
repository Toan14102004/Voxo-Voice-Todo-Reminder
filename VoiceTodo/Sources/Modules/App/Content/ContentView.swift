//
//  ContentView.swift
//  VoiceTodo
//
//  Created by Toan Nguyen on 26/9/25.
//

import SwiftUI

enum Tab: CaseIterable {
    case home, explore, activity, profile

    var title: String {
        switch self {
        case .home: "Home"
        case .explore: "Explore"
        case .activity: "Activity"
        case .profile: "Profile"
        }
    }

    // TODO: swap for your app's tab icons.
    var systemIcon: String {
        switch self {
        case .home: "house.fill"
        case .explore: "safari.fill"
        case .activity: "chart.bar.fill"
        case .profile: "person.fill"
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @StateObject private var viewModel = ViewModel()
    @ObservedObject private var languageManager = LanguageManager.shared
    @State var currentTab: Tab = .home

    var body: some View {
        VStack(spacing: 0) {
            header()

            TabView(selection: $currentTab) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    // TODO: replace with real screens for each tab.
                    placeholderContent(for: tab)
                        .tag(tab)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Asset.Color.bgPrimary.color.ignoresSafeArea())
        .overlay(alignment: .bottom) {
            tabBar()
        }
        .navigationBarBackButtonHidden(true)
        .flowDestination(for: Coordinator.Navigation.self) { item in
            switch item {
            case .settingView:
                SettingView(viewModel: .init())
            case .languageView:
                LanguageView(viewModel: .init())
            }
        }
        .popup(item: $viewModel.coordinator.alert) { item in
            switch item {
            case .error(let title, let message):
                CustomAlertView(
                    title: LocalizedStringKey(title),
                    titleColor: .red,
                    description: LocalizedStringKey(message),
                    primaryActionTitle: "OK",
                    primaryAction: {
                        viewModel.coordinator.alert = nil
                    }
                )
            case .success(let title, let message):
                CustomAlertView(
                    title: LocalizedStringKey(title),
                    titleColor: .green,
                    description: LocalizedStringKey(message),
                    primaryActionTitle: "OK",
                    primaryAction: {
                        viewModel.coordinator.alert = nil
                    }
                )
            }
        } customize: { params in
            params.centerPopup()
        }
    }

    @ViewBuilder
    func header() -> some View {
        HStack(spacing: Layout.Spacing.s) {
            Text(currentTab.title)
                .foregroundStyle(Asset.Color.textPrimary.color)
                .font(FontFamily.Mulish.bold.font(size: Layout.Text.title1))
                .frame(maxWidth: .infinity, alignment: .leading)

            if !subscriptionManager.isSubscribed {
                Button {
                    viewModel.showPremiumFullScreen()
                } label: {
                    Asset.Icon.Commo.premium.image
                        .toIcon(28.iPad(32))
                }
            }

            Button {
                viewModel.openLanguageView()
            } label: {
                Text(languageManager.currentLanguageCode.uppercased())
                    .font(FontFamily.Mulish.bold.font(size: Layout.Text.footnote))
                    .foregroundStyle(Asset.Color.textPrimary.color)
                    .padding(.horizontal, Layout.Spacing.xs)
                    .padding(.vertical, Layout.Spacing.xxs)
                    .overlay(RoundedRectangle(cornerRadius: Layout.CornerRadius.small).stroke(Asset.Color.borderPrimary.color, lineWidth: 1))
            }
        }
        .frame(height: Layout.Button.largeHeight)
        .padding(.horizontal, Layout.Spacing.m)
        .frame(maxWidth: .infinity)
        .background(Asset.Color.bgPrimary.color)
    }

    @ViewBuilder
    func placeholderContent(for tab: Tab) -> some View {
        VStack(spacing: Layout.Spacing.s) {
            Spacer()
            Image(systemName: tab.systemIcon)
                .font(.system(size: 40))
                .foregroundStyle(Asset.Color.textBrandPrimary.color)
            Text("\(tab.title) screen")
                .font(FontFamily.Mulish.bold.font(size: Layout.Text.title3))
                .foregroundStyle(Asset.Color.textPrimary.color)
            Text("Replace with your feature screen.")
                .font(FontFamily.Mulish.regular.font(size: Layout.Text.callout))
                .foregroundStyle(Asset.Color.textTertiary.color)
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, Layout.Spacing.xxl * 2)
    }

    @ViewBuilder
    func tabBar() -> some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Button {
                    currentTab = tab
                } label: {
                    VStack(spacing: Layout.Spacing.xxs) {
                        Image(systemName: tab.systemIcon)
                            .font(.system(size: Layout.Icon.xs))
                        Text(tab.title)
                            .font(FontFamily.Mulish.medium.font(size: Layout.Text.caption2))
                    }
                    .foregroundStyle(
                        currentTab == tab
                            ? Asset.Color.textBrandPrimary.color
                            : Asset.Color.textTertiary.color
                    )
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.top, Layout.Spacing.xxs)
        .padding(.bottom, Layout.Spacing.xxs)
        .background(
            Asset.Color.bgPrimary.color
                .overlay(alignment: .top) {
                    Asset.Color.borderPrimary.color.frame(height: 1)
                }
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

#Preview {
    ContentView()
        .preview()
}
