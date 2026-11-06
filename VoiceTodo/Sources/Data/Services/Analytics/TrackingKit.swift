//
//  TrackingKit.swift
//  VoiceTodo
//
//  Điểm duy nhất nói chuyện với Adjust / Meta / TikTok (+ Firebase cho purchase).
//  Quy tắc (xem skill ios-tracking-integration):
//   - Adjust là MMP duy nhất và là người ghi SKAN conversion value duy nhất.
//   - `start()` chạy MỌI launch, KHÔNG gate theo consent/subscribed (chỉ ads SDK mới gate).
//   - Purchase đi qua đúng 1 hàm `logVerifiedPurchase`, ad revenue qua đúng 1 hàm `handleAdPaidEvent`.
//   - Cấm gọi trực tiếp AppEvents.logPurchase / Adjust.trackEvent có revenue / TikTokBusiness.track* /
//     SKAdNetwork.* ở nơi khác.
//   - ATT do UMP của AdMob lo; app không tự gọi ATT.
//

import AdjustSdk
import FBSDKCoreKit
import FirebaseAnalytics
import Foundation
import TikTokBusinessSDK
import UIKit

// MARK: - Per-app profile (chốt với team UA TRƯỚC khi build)

enum TrackingConfig {
    /// true: Meta nhận purchase + ad revenue trực tiếp từ FB SDK (tổng IAA+IAP).
    /// false: Meta nhận event qua Adjust forward; code KHÔNG được gọi logPurchase.
    static let metaDirectHybrid = true
    /// true: ad revenue sang TikTok qua SDK (nhớ TẮT share ad-revenue Adjust -> TikTok trên dashboard).
    static let tiktokAdRevenueViaSDK = true
    /// true: bắn thêm `ad_revenue_d0` vào GA4 (app IAA-heavy chạy tROAS Google).
    static let googleSeesAdRevenue = false
    /// k% giá cho free trial (expected value) - nên nối Remote Config `freeTrialPredictPercentValue`.
    static var trialPredictPercent: Double { 20 }
}

// MARK: - TrackingKit

final class TrackingKit: NSObject {
    static let shared = TrackingKit()
    private override init() {}

    private var didReleaseFirstSessionDelay = false

    /// Gọi trong `didFinishLaunchingWithOptions`, SAU `FirebaseApp.configure()` + FB `ApplicationDelegate`.
    func start() {
        startAdjust()
        startTikTok()
        // Auto-log đã tắt trong Info.plist -> gọi tay để giữ install ping + AEM.
        AppEvents.shared.activateApp()
    }

    // MARK: Adjust

    private func startAdjust() {
        guard AppConfiguration.isConfigured(AppConfiguration.adjustToken) else {
            Logger.d(messages: "[Adjust] ADJUST_TOKEN chưa cấu hình, bỏ qua init")
            return
        }
        #if DEBUG
        let environment = ADJEnvironmentSandbox as String
        #else
        let environment = ADJEnvironmentProduction as String // CẤM đổi theo runtime/debug-menu
        #endif
        let config = ADJConfig(appToken: AppConfiguration.adjustToken, environment: environment)
        config?.delegate = self
        config?.enableSendingInBackground()
        config?.enableFirstSessionDelay() // giữ install payload chờ ATT (UMP) - nhớ gọi releaseFirstSessionDelay()
        #if DEBUG
        config?.logLevel = ADJLogLevel.verbose
        #else
        config?.logLevel = ADJLogLevel.suppress
        #endif
        Adjust.initSdk(config)
        // CẤM: disableSkanAttribution() / updateSkanConversionValue(...) / SKAdNetwork.* trực tiếp.

        // An toàn: nếu UMP không bao giờ trả về thì vẫn thả install payload.
        DispatchQueue.main.asyncAfter(deadline: .now() + 60) { [weak self] in
            self?.releaseFirstSessionDelay()
        }
    }

    /// Gọi sau khi UMP/ATT xong (kể cả user từ chối hoặc UMP lỗi). Không gọi thì install không bao giờ bay.
    func releaseFirstSessionDelay() {
        guard !didReleaseFirstSessionDelay else { return }
        didReleaseFirstSessionDelay = true
        Adjust.endFirstSessionDelay()
    }

    // MARK: TikTok (signal-only)

    private func startTikTok() {
        guard AppConfiguration.isConfigured(AppConfiguration.tiktokAccessToken),
              AppConfiguration.isConfigured(AppConfiguration.tiktokAppId),
              !AppConfiguration.appStoreNumericId.isEmpty else {
            Logger.d(messages: "[TikTok] chưa cấu hình, bỏ qua init")
            return
        }
        let config = TikTokConfig(
            accessToken: AppConfiguration.tiktokAccessToken,
            appId: AppConfiguration.appStoreNumericId,
            tiktokAppId: AppConfiguration.tiktokAppId
        )
        // MMP (Adjust) quản conversion value -> tắt toàn bộ auto-tracking của TikTok.
        config?.disableSKAdNetworkSupport()
        config?.disableAutomaticTracking()
        config?.disableInstallTracking()
        config?.disableLaunchTracking()
        config?.disableRetentionTracking()
        config?.disablePaymentTracking()
        #if DEBUG
        config?.enableDebugMode()
        #endif
        TikTokBusiness.initializeSdk(config) { success, error in
            Logger.d(messages: "[TikTok] init", success, error?.localizedDescription ?? "")
        }
        // CẤM: identify() khi không có email/phone thật · logout() · event tên "Purchase".
    }

    // MARK: - Purchase

    struct PurchaseInfo {
        let productId: String
        let transactionId: String
        let originalTransactionId: String
        /// Giá thật của product (kể cả khi là free trial).
        let price: Double
        let currency: String
        let isFreeTrial: Bool
    }

    /// Mọi đường purchase/renewal đi qua đây, UI KHÔNG tự log. Dedupe theo `transactionId`.
    func logVerifiedPurchase(_ purchase: PurchaseInfo) {
        guard markTracked(purchase.transactionId) else { return }

        let k = TrackingConfig.trialPredictPercent / 100.0
        let trackedValue = purchase.isFreeTrial ? purchase.price * k : purchase.price // trial = k x giá, không bao giờ full price

        // 1) Firebase
        Analytics.logEvent(AnalyticsEventPurchase, parameters: [
            AnalyticsParameterTransactionID: purchase.transactionId,
            AnalyticsParameterCurrency: purchase.currency,
            AnalyticsParameterValue: trackedValue,
            "value_type": purchase.isFreeTrial ? "predicted_free_trial" : "actual_price",
            "product_id": purchase.productId,
            "original_transaction_id": purchase.originalTransactionId
        ])

        // 2) Adjust - một event purchase kèm revenue + stream subscription riêng
        let token = AppConfiguration.adjustPurchaseToken
        if AppConfiguration.isConfigured(token), let event = ADJEvent(eventToken: token) {
            event.setRevenue(trackedValue, currency: purchase.currency)
            event.setDeduplicationId(purchase.transactionId)
            Adjust.trackEvent(event)
        } else {
            Logger.d(messages: "[Adjust] ADJUST_PURCHASE_TOKEN chưa cấu hình, bỏ qua event purchase")
        }
        if let subscription = ADJAppStoreSubscription(
            price: NSDecimalNumber(value: purchase.price),
            currency: purchase.currency,
            transactionId: purchase.transactionId
        ) {
            Adjust.trackAppStoreSubscription(subscription)
        }

        // 3) Meta - chỉ profile meta-direct
        if TrackingConfig.metaDirectHybrid {
            AppEvents.shared.logPurchase(
                amount: trackedValue,
                currency: purchase.currency,
                parameters: [
                    AppEvents.ParameterName("fb_content_id"): purchase.productId,
                    AppEvents.ParameterName("fb_transaction_id"): purchase.transactionId
                ]
            )
        }
        // 4) TikTok: KHÔNG bắn purchase từ client - Adjust SAN forward lo.
    }

    // MARK: - Ad revenue (gắn vào paidEventHandler của MỌI format, kể cả rewarded)

    /// - Parameter amount: `AdValue.value` đã là đơn vị tiền (không phải micros).
    func handleAdPaidEvent(network: String, amount: Double, currency: String, precision: Int, adUnitId: String) {
        // 1) Adjust - đúng 1 đường trackAdRevenue
        if let adRevenue = ADJAdRevenue(source: "admob_sdk") {
            adRevenue.setRevenue(amount, currency: currency)
            adRevenue.setAdRevenueNetwork(network)
            adRevenue.setAdRevenueUnit(adUnitId)
            Adjust.trackAdRevenue(adRevenue)
        }
        // 2) Meta - chỉ profile meta-direct
        if TrackingConfig.metaDirectHybrid {
            AppEvents.shared.logPurchase(
                amount: amount,
                currency: currency,
                parameters: [AppEvents.ParameterName("ad_network"): network]
            )
        }
        // 3) TikTok qua SDK khi bật cờ
        if TrackingConfig.tiktokAdRevenueViaSDK {
            let payload: [String: Any] = [
                "device_ad_mediation_platform": "admob_sdk",
                "value": amount,
                "currency_code": currency,
                "precision": precision,
                "ad_source_name": network
            ]
            TikTokBusiness.trackTTEvent(TikTokAdRevenueEvent(adRevenue: payload, eventId: UUID().uuidString))
        }
        // 4) Google - chỉ app IAA-heavy chạy tROAS Google
        if TrackingConfig.googleSeesAdRevenue {
            Analytics.logEvent("ad_revenue_d0", parameters: [
                AnalyticsParameterCurrency: currency,
                AnalyticsParameterValue: amount,
                "ad_network": network,
                "ad_unit": adUnitId
            ])
        }
    }

    // MARK: - Helpers

    private func markTracked(_ transactionId: String) -> Bool {
        let key = "tk.tracked.tx"
        var set = Set(UserDefaults.standard.stringArray(forKey: key) ?? [])
        guard !set.contains(transactionId) else { return false }
        set.insert(transactionId)
        UserDefaults.standard.set(Array(set.suffix(500)), forKey: key)
        return true
    }
}

// MARK: - AdjustDelegate (observability)

extension TrackingKit: AdjustDelegate {
    func adjustSkanUpdated(withConversionData data: [String: String]) {
        Logger.d(messages: "[Adjust][SKAN]", data)
    }

    func adjustEventTrackingFailed(_ eventFailureResponseData: ADJEventFailure?) {
        Logger.d(messages: "[Adjust][FAIL]", eventFailureResponseData?.message ?? "")
    }
}
