//
//  RootView.swift
//  VoiceTodo
//
//  Created by Toan Nguyen on 18/11/24.
//

import Combine
import Foundation
import SwiftUI
import VoxoDesign

struct RootView: View {
    @Injected var subscriptionManager: SubscriptionManager
    @Injected var adsManager: AdsManager
    @Injected var localStorageService: LocalStorageService
    @Environment(\.scenePhase) private var scenePhase
    
    @EnvironmentObject var loadingService: LoadingService
    @Environment(\.injected) private var injected: DIContainer
    @ObservedObject var viewModel: ViewModel
    @ObservedObject var languageManager = LanguageManager.shared

    var body: some View {
        #if DEBUG
            // Phase 0 harness: the "VoiceTodo-Phase0" scheme passes -phase0Probe.
            // Remove together with Sources/Modules/Phase0.
            if ProcessInfo.processInfo.arguments.contains("-phase0Probe") {
                NotificationProbeView(isRoot: true)
            } else if ProcessInfo.processInfo.arguments.contains("-gallery") {
                // Every design-system component on one screen, to compare against the Figma board.
                VoxoComponentGallery()
            } else if ProcessInfo.processInfo.arguments.contains("-templateUI") {
                // Escape hatch back to the BaseSource demo flow (splash, onboarding, paywall),
                // kept only so the template's ad/IAP wiring can still be exercised.
                templateUI
            } else {
                VoxoRootView()
            }
        #else
            VoxoRootView()
        #endif
    }

    /// The BaseSource template's screens hardcode white-on-black, so they stay pinned to dark.
    private var templateUI: some View {
        templateContent
            .colorScheme(.dark)
    }

    private var templateContent: some View {
        ZStack {
            FlowStack($viewModel.path, withNavigation: true) {
                SplashView()
                    .modifier(NavigatorModifier())
                    .flowDestination(for: Coordinator.Navigation.self) { item in
                        switch item {
                        case .language: LanguageView(viewModel: .init(isOnboardingContext: true))
                        case .content: ContentView()
                        }
                    }
                    .flowDestination(for: Coordinator.FullScreen.self) { item in
                        switch item {
                        case let .subscription(subscriptionEntryPoint): SubscriptionView(subscriptionEntryPoint: subscriptionEntryPoint)
                        }
                    }
            }
            .environmentObject(subscriptionManager)
            .environment(\.locale, languageManager.currentLocale)
            .environment(\.layoutDirection, languageManager.layoutDirection)
            
            if loadingService.isLoading {
                VStack {
                    ActivityIndicatorView(
                        isVisible: $loadingService.isLoading,
                        type: loadingService.indicatorType
                    )
                    .foregroundColor(loadingService.indicatorColor)
                    .frame(
                        width: Layout.Spacing.xxl,
                        height: Layout.Spacing.xxl
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.black.opacity(0.3))
            }
        }
    }
}

#Preview(body: {
    ContentView()
        .preview()
})
