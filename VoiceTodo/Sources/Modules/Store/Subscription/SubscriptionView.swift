//
//  SubscriptionView.swift
//  VoiceTodo
//
//  Created by Toan Nguyen on 19/6/25.
//

import Foundation
import StoreKit
import SwiftUI

struct SubscriptionView: View {
    @Injected var firebaseAnalyticsService: FirebaseAnalyticsService
    @Injected var localStorageService: LocalStorageService
    @Injected var adsManager: AdsManager
    
    @Navigation var navigator
    
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @StateObject var viewModel: ViewModel
    
    @State private var canClose: Bool = false
    
    let subscriptionEntryPoint: SubscriptionEntryPoint
    
    init(subscriptionEntryPoint: SubscriptionEntryPoint) {
        self.subscriptionEntryPoint = subscriptionEntryPoint
        self._viewModel = StateObject(
            wrappedValue: ViewModel(subscriptionEntryPoint: subscriptionEntryPoint))
    }
    
    var body: some View {
        VStack(spacing: Layout.Spacing.m) {
            ScrollView {
                headerWithTitleOverlay()
               
                featureTableSection()
                
                planSelectorSection()
                
                priceDisplaySection()
                   
                subscribeButton()
                 
                Spacer()
                bottomBar()
                    .padding(.bottom, Layout.Spacing.l)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Asset.Color.black.color.ignoresSafeArea(.all))
        .ignoresSafeArea(.all, edges: .top)
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
                    titleColor: Asset.Color.mainColor.color,
                    description: LocalizedStringKey(message),
                    primaryActionTitle: "OK",
                    primaryAction: viewModel.onSubscriptionSuccess
                )
            }
        } customize: {
            $0.centerPopup()
        }
        .popup(
            isPresented: $subscriptionManager.isLoading,
            view: {
                LoadingView(isLoading: $subscriptionManager.isLoading)
            },
            customize: {
                $0.centerPopup()
                    .closeOnTapOutside(false)
            }
        )
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar(content: {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.goBack()
                } label: {
                    Asset.Icon.Commo.xmark.image
                        .toIcon()
                        .foregroundStyle(Asset.Color.white.color.opacity(0.5))
                        .padding(Layout.Spacing.s)
                }
                .opacity(canClose ? 1 : 0)
                .allowsHitTesting(canClose)
            }
        })
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    canClose = true
                }
            }
        }
        .trackImpression(subscriptionEntryPoint.trackImpressionName)
        .trackScreen(
            subscriptionEntryPoint.screenName, parameters: ["page_name": subscriptionEntryPoint.pageName]
        )
    }
}

// MARK: - Header + Title Overlay

private extension SubscriptionView {
    @ViewBuilder
    func headerWithTitleOverlay() -> some View {
        ZStack(alignment: .bottom) {
            Asset.Image.Premium.premiumBanner.image
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .overlay(alignment: .bottom) {
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Asset.Color.black.color.opacity(0.7),
                            Asset.Color.black.color
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 60)
                }
            
            Asset.Image.Premium.textOverlay.image
                .resizable()
                .scaledToFit()
                .padding(.horizontal, Layout.Spacing.l)
                .offset(y: -8)
        }
        .fixedSize(horizontal: false, vertical: true)
        .layoutPriority(1)
    }
}

// MARK: - Feature Table Section

private extension SubscriptionView {
    struct FeatureItem {
        let icon: Image
        let name: LocalizedStringKey
        let basicValue: FeatureValue
        let premiumValue: FeatureValue
    }
    
    enum FeatureValue {
        case check
        case cross
        case text(LocalizedStringKey)
    }
    
    var features: [FeatureItem] {
        [
            FeatureItem(
                icon: Asset.Icon.Commo.icNoads.image,
                name: "No ads",
                basicValue: .cross,
                premiumValue: .check
            ),
            FeatureItem(
                icon: Asset.Icon.Commo.premium.image,
                name: "Premium features",
                basicValue: .cross,
                premiumValue: .check
            ),
            FeatureItem(
                icon: Asset.Icon.Commo.locked.image,
                name: "Unlimited usage",
                basicValue: .text("Limit"),
                premiumValue: .check
            )
        ]
    }
    
    @ViewBuilder
    func featureTableSection() -> some View {
        ZStack(alignment: .trailing) {
            RoundedRectangle(cornerRadius: Layout.CornerRadius.large)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Asset.Color.mainColor.color.opacity(0.5)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 80.iPad(130))
                .padding(.trailing, Layout.Spacing.l)
                .blur(radius: 1)
            
            VStack(spacing: 0) {
                HStack {
                    Text("Feature".localizedKey)
                        .font(FontFamily.Mulish.bold.font(size: Layout.Text.footnote))
                        .foregroundStyle(Asset.Color.grayText.color)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("BASIC".localizedKey)
                        .font(FontFamily.Mulish.bold.font(size: Layout.Text.subheadline))
                        .foregroundStyle(Asset.Color.grayText.color)
                        .frame(width: 80.iPad(115))
                    
                    Text("PREMIUM".localizedKey)
                        .font(FontFamily.Mulish.bold.font(size: Layout.Text.subheadline))
                        .foregroundStyle(Asset.Color.white.color)
                        .frame(width: 80.iPad(130))
                }
                .padding(.horizontal, Layout.Spacing.l)
                .padding(.bottom, Layout.Spacing.m)
               
                ForEach(0 ..< features.count, id: \.self) { index in
                    let feature = features[index]
                    featureRow(feature: feature)
                }
            }
        }
    }
    
    @ViewBuilder
    func featureRow(feature: FeatureItem) -> some View {
        HStack {
            HStack(spacing: Layout.Spacing.s) {
                feature.icon
                    .resizable()
                    .scaledToFit()
                    .frame(width: Layout.Icon.medium, height: Layout.Icon.medium)
                    .foregroundStyle(Asset.Color.white.color)
                
                Text(feature.name)
                    .font(FontFamily.Mulish.medium.font(size: Layout.Text.subheadline))
                    .foregroundStyle(Asset.Color.white.color)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
          
            featureValueView(value: feature.basicValue)
                .frame(width: 80.iPad(115))
            
            featureValueView(value: feature.premiumValue)
                .frame(width: 80.iPad(130))
        }
        .padding(.horizontal, Layout.Spacing.l)
        .padding(.vertical, Layout.Spacing.s)
    }
    
    @ViewBuilder
    func featureValueView(value: FeatureValue) -> some View {
        switch value {
        case .check:
            Asset.Icon.Commo.checkPremium.image
                .toIcon(24.iPad(28))
        case .cross:
            Image(systemName: "xmark")
                .font(.system(size: Layout.Text.body, weight: .bold))
                .foregroundStyle(Asset.Color.white.color)
        case .text(let string):
            Text(string)
                .font(FontFamily.Mulish.medium.font(size: Layout.Text.subheadline))
                .foregroundStyle(Asset.Color.grayText.color)
        }
    }
}

// MARK: - Plan Selector Section

private extension SubscriptionView {
    @ViewBuilder
    func planSelectorSection() -> some View {
        HStack(spacing: Layout.Spacing.xs) {
            ForEach(PlanTab.allCases, id: \.self) { tab in
                planTabButton(tab: tab)
            }
        }
        .padding(Layout.Spacing.xxs)
        .background(
            RoundedRectangle(cornerRadius: Layout.CornerRadius.xxxl)
                .fill(Asset.Color.white.color)
        )
        .padding(.horizontal, Layout.Spacing.xxxl)
    }
    
    @ViewBuilder
    func planTabButton(tab: PlanTab) -> some View {
        let isSelected = viewModel.selectedTab == tab
        
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.selectedTab = tab
                viewModel.updateSelectedProduct()
            }
        } label: {
            ZStack(alignment: .topTrailing) {
                Text(tab.displayName)
                    .font(FontFamily.Mulish.semiBold.font(size: Layout.Text.subheadline))
                    .foregroundStyle(isSelected ? Asset.Color.white.color : Asset.Color.black.color.opacity(0.35))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Layout.Spacing.s)
                    .background(
                        Capsule()
                            .fill(isSelected ? Asset.Color.mainColor.color : Color.clear)
                    )
                
                if tab == .yearly {
                    Asset.Icon.Commo.saleTag.image
                        .toIcon(24.iPad(28))
                        .offset(x: 4, y: -12)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Price Display Section

private extension SubscriptionView {
    @ViewBuilder
    func priceDisplaySection() -> some View {
        let product = viewModel.selectedProduct(from: subscriptionManager.availableProducts)
        let subscription = product.flatMap { AutoRenewableSubscription(productId: $0.id) }
        
        HStack {
            Text(viewModel.selectedTab.planName)
                .font(FontFamily.Mulish.bold.font(size: Layout.Text.body))
                .foregroundStyle(Asset.Color.white.color)
            
            Spacer()
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                if let product = product {
                    Text(product.displayPrice)
                        .font(FontFamily.Mulish.bold.font(size: Layout.Text.title2))
                        .foregroundStyle(Asset.Color.white.color)
                } else {
                    Text("---")
                        .font(FontFamily.Mulish.bold.font(size: Layout.Text.title2))
                        .foregroundStyle(Asset.Color.white.color)
                }
                
                Text("/")
                    .font(FontFamily.Mulish.bold.font(size: Layout.Text.title2))
                    .foregroundStyle(Asset.Color.white.color)
                
                Text(viewModel.selectedTab.periodSuffix.localizedKey)
                    .font(FontFamily.Mulish.regular.font(size: Layout.Text.subheadline))
                    .foregroundStyle(Asset.Color.grayText.color)
            }
        }
        .padding(.horizontal, Layout.Spacing.l)
        .padding(.vertical, Layout.Spacing.l)
        .background(
            RoundedRectangle(cornerRadius: Layout.CornerRadius.large)
                .stroke(Asset.Color.mainColor.color, lineWidth: Layout.StrokeWidth.thick)
        )
        .padding(.horizontal, Layout.Spacing.l)
       
        // Free trial info
        if let product = product,
           let introInfo = subscriptionManager.getIntroductoryOfferInfo(for: product.id),
           introInfo.isEligible,
           case .freeTrial = introInfo.type
        {
            HStack(spacing: 0) {
                Text(introInfo.subscriptionPeriod.localizedKey)
                Text(" ")
                Text("free trial, then".localizedKey)
                Text(" ")
                Text(product.displayPrice)
                Text("/")
                Text(periodUnit(subscription).localizedKey)
            }
            .font(FontFamily.Mulish.regular.font(size: Layout.Text.caption1))
            .foregroundStyle(Asset.Color.grayText.color)
            .padding(.top, Layout.Spacing.xs)
        }
    }
    
    func hasIntroOffer(for productId: String) -> Bool {
        guard let introInfo = subscriptionManager.getIntroductoryOfferInfo(for: productId),
              introInfo.isEligible
        else {
            return false
        }
        return true
    }
    
    func periodUnit(_ subscription: AutoRenewableSubscription?) -> String {
        switch subscription {
        case .yearly, .yearlyFreeTrial: return "year"
        case .monthly, .monthlyFreeTrial: return "month"
        case .weekly, .weeklyFreeTrial: return "week"
        case .none: return "period"
        }
    }
}

// MARK: - Subscribe Button

extension SubscriptionView {
    @ViewBuilder
    fileprivate func subscribeButton() -> some View {
        Button {
            viewModel.purchaseSelectedProduct()
        } label: {
            Text(continueButtonText)
                .font(FontFamily.Mulish.bold.font(size: Layout.Text.body))
                .foregroundStyle(Asset.Color.white.color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Layout.Spacing.m)
                .background(
                    RoundedRectangle(cornerRadius: Layout.CornerRadius.xxxl)
                        .fill(Asset.Color.mainColor.color)
                )
        }
        .padding(.horizontal, Layout.Spacing.l)
    }
    
    private var continueButtonText: LocalizedStringKey {
        guard !viewModel.selectedProductId.isEmpty,
              let introOfferInfo = subscriptionManager.getIntroductoryOfferInfo(
                  for: viewModel.selectedProductId),
              introOfferInfo.isEligible
        else {
            return "Subscribe Now"
        }
        
        return "Subscribe Now"
    }
}

// MARK: - Bottom Bar

private extension SubscriptionView {
    @ViewBuilder
    func bottomBar() -> some View {
        VStack(spacing: Layout.Spacing.s) {
            HStack {
                Button {
                    viewModel.openTermsOfService()
                } label: {
                    Text("Term & Conditions")
                        .font(FontFamily.Mulish.regular.font(size: Layout.Text.caption1))
                        .minimumScaleFactor(0.5)
                        .underline()
                }
                
                Spacer()

                Button {
                    viewModel.restorePurchases()
                } label: {
                    Text("Restore")
                        .font(FontFamily.Mulish.regular.font(size: Layout.Text.caption1))
                        .minimumScaleFactor(0.5)
                        .underline()
                }

                Spacer()
                
                Button {
                    viewModel.openPrivacyPolicy()
                } label: {
                    Text("Privacy policy")
                        .font(FontFamily.Mulish.regular.font(size: Layout.Text.caption1))
                        .minimumScaleFactor(0.5)
                        .underline()
                }
            }
            .foregroundStyle(Asset.Color.grayText.color)
            .padding(.horizontal, Layout.Spacing.l)
            
            disclaimerText()
        }
    }
    
    @ViewBuilder
    func disclaimerText() -> some View {
        Text("Your account will be charged within 24 hours prior to the end of the current period. You can manage or cancel your subscription at any time in your App Store account settings".localizedKey)
            .font(FontFamily.Mulish.regular.font(size: Layout.Text.caption2))
            .foregroundStyle(Asset.Color.grayText.color)
            .multilineTextAlignment(.center)
            .padding(.horizontal, Layout.Spacing.l)
    }
}

#Preview {
    SubscriptionView(subscriptionEntryPoint: .home)
        .preview()
        .environmentObject(SubscriptionManager())
}
