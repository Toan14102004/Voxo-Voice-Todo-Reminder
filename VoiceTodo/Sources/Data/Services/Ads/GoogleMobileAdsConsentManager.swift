//
//  GoogleMobileAdsConsentManager.swift
//  VoiceTodo
//
//  UMP (Google User Messaging Platform) là nơi DUY NHẤT hiện ATT: message IDFA/ATT cấu hình trên
//  AdMob console. App không tự gọi ATTrackingManager và không làm màn explainer riêng.
//

import AppLovinSDK
import AppTrackingTransparency
import FBAudienceNetwork
import Foundation
import GoogleMobileAds
import UIKit
import UserMessagingPlatform

final class GoogleMobileAdsConsentManager {
    static let shared = GoogleMobileAdsConsentManager()
    private init() {}

    private var didStartMobileAds = false

    var canRequestAds: Bool {
        ConsentInformation.shared.canRequestAds
    }

    var isPrivacyOptionsRequired: Bool {
        ConsentInformation.shared.privacyOptionsRequirementStatus == .required
    }

    /// Gọi mỗi lần mở app: cập nhật consent info và hiện form (kèm ATT) nếu cần.
    func gatherConsent(
        from viewController: UIViewController?,
        completion: @escaping (Error?) -> Void
    ) {
        let parameters = RequestParameters()
        #if DEBUG
        // Test EEA: thêm test device id vào MobileAds.shared.requestConfiguration.testDeviceIdentifiers.
        let debugSettings = DebugSettings()
        debugSettings.testDeviceIdentifiers = MobileAds.shared.requestConfiguration.testDeviceIdentifiers
        parameters.debugSettings = debugSettings
        #endif

        ConsentInformation.shared.requestConsentInfoUpdate(with: parameters) { requestError in
            if let requestError {
                completion(requestError)
                return
            }
            guard let viewController else {
                completion(nil)
                return
            }
            ConsentForm.loadAndPresentIfRequired(from: viewController) { formError in
                completion(formError)
            }
        }
    }

    func presentPrivacyOptionsForm(from viewController: UIViewController, completion: @escaping (Error?) -> Void) {
        ConsentForm.presentPrivacyOptionsForm(from: viewController, completionHandler: completion)
    }

    /// Quảng cáo cá nhân hoá chỉ khi UMP cho phép VÀ user đã cấp ATT (không hardcode true).
    private var canUsePersonalisedAds: Bool {
        canRequestAds && ATTrackingManager.trackingAuthorizationStatus == .authorized
    }

    /// Báo trạng thái consent thật cho các mạng mediation (Meta, AppLovin). Gọi trước khi start MobileAds.
    func applyMediationPrivacy() {
        let allowed = canUsePersonalisedAds
        FBAdSettings.setAdvertiserTrackingEnabled(allowed)
        ALPrivacySettings.setHasUserConsent(allowed)
        ALPrivacySettings.setDoNotSell(!allowed)
    }

    /// Chỉ ads SDK mới bị gate bởi consent. An toàn khi gọi nhiều lần.
    func startMobileAdsIfAllowed() {
        guard canRequestAds, !didStartMobileAds else { return }
        didStartMobileAds = true
        applyMediationPrivacy()
        MobileAds.shared.start { status in
            for (adapter, state) in status.adapterStatusesByClassName {
                Logger.d(messages: "Adapter:", adapter, state.description, state.state.rawValue)
            }
        }
    }
}
