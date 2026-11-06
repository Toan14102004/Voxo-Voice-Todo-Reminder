//
//  SplashView.swift
//  MapTracking
//
//  Created by Toan Nguyen on 17/4/25.
//

import SwiftUI

struct SplashView: View {
    @Navigation var navigator
    
    @Injected var localStorageService: LocalStorageService
    @Injected var adsManager: AdsManager
    
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var loadingProgress: CGFloat = 0.0
    @State private var didShowAds: Bool = false
    @State private var hasNavigated: Bool = false
    
    @State private var isRemoteConfigReady: Bool = false
    @State private var didRequestAppTracking: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            Asset.Assets.appstore.image
                .toIcon(Layout.Spacing.xxl * 5)
                .cornerRadius(radius: Layout.CornerRadius.large, corners: .allCorners)
                .padding(.bottom, Layout.Spacing.m)
            
            Text("VoiceTodo")
                .font(FontFamily.Mulish.bold.font(size: Layout.Text.title1))
                .foregroundStyle(Asset.Color.mainColor.color)
            
            Spacer()

            VStack(spacing: Layout.Spacing.m) {
                GeometryReader { proxy in
                    let width = proxy.size.width
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Asset.Color.white.color.opacity(0.85))
                            .frame(height: Layout.Spacing.s)

                        Capsule()
                            .fill(Asset.Color.mainColor.color)
                            .frame(width: width * max(0, min(1, loadingProgress)), height: Layout.Spacing.s)
                    }
                }
                .frame(height: Layout.Spacing.s)
                .padding(.horizontal, Layout.Spacing.l * 2)

                Text("This action may contain ads")
                    .font(FontFamily.Mulish.regular.font(size: Layout.Text.callout))
                    .foregroundStyle(Asset.Color.white.color.opacity(0.4))
            }
            .padding(.bottom, UIApplication.shared.safeAreaBottom + Layout.Spacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Asset.Color.black.color)
        .trackScreen("splashVC")
        .onAppear {
            withAnimation(.easeInOut(duration: 5)) {
                loadingProgress = 0.5
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8, execute: {
                gatherConsent {
                    didRequestAppTracking = true
                    handlePushNext()
                }
            })
        }
        .onReceive(NotificationCenter.default.publisher(for: .remoteConfigReady)) { _ in
            isRemoteConfigReady = true
            handlePushNext()
        }
        .onChange(of: subscriptionManager.isLoading) { isLoading in
            if !isLoading {
                handlePushNext()
            }
        }
    }
}

// MARK: Func
private extension SplashView {
    
    /// UMP hiện form consent (kèm ATT nếu đã cấu hình trên AdMob console). App không tự gọi ATT.
    func gatherConsent(completion: @escaping () -> Void) {
        GoogleMobileAdsConsentManager.shared.gatherConsent(from: UIApplication.shared.currentUIWindow?.rootViewController) { error in
            DispatchQueue.main.async {
                if let error {
                    Logger.d(messages: "UMP error:", error.localizedDescription)
                }
                TrackingKit.shared.releaseFirstSessionDelay()
                GoogleMobileAdsConsentManager.shared.applyMediationPrivacy() // cập nhật lại sau khi user trả lời UMP/ATT
                GoogleMobileAdsConsentManager.shared.startMobileAdsIfAllowed()
                completion()
            }
        }
    }
    
    func handlePushNext() {
        guard didRequestAppTracking && isRemoteConfigReady && !subscriptionManager.isLoading && !hasNavigated else { return }
        
        guard localStorageService.isFirstTimeOpenApp else {
            if localStorageService.isDisplayPremiumAfterSplash && !subscriptionManager.isSubscribed {
                showSplashInter {
                    DispatchQueue.main.async {
                        navigator.push(RootView.Coordinator.FullScreen.subscription(subscriptionEntryPoint: .onboardingSecond))
                    }
                }
            } else {
                showSplashInter {
                    DispatchQueue.main.async {
                        navigator.push(RootView.Coordinator.Navigation.content)
                    }
                }
            }
            hasNavigated = true
            return
        }
        
        showSplashInter {
            navigator.push(RootView.Coordinator.Navigation.language)
        }
        hasNavigated = true
    }
    
    func showSplashInter(action: @escaping () -> Void) {
        let adPlacement = localStorageService.interSplash
        let adPlacementHight = localStorageService.interSplashHight
        adsManager.showSplashInterstitial(
            adPlacement: adPlacement,
            adPlacementHigh: adPlacementHight,
            onDismissed: {
                action()
            },
            onFailed: { _ in
                action()
            })
    }
}

#Preview {
    SplashView()
        .preview()
}
