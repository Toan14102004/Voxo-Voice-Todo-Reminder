//
//  FirebaseRemoteConfig.swift
//  VoiceTodo
//
//  Created by Toan Nguyen on 18/6/25.
//

import FirebaseCore
import FirebaseRemoteConfig
import Foundation

enum FirebaseRemoteConfigKey: String, CaseIterable {
    // Subscription
    case weekly_free_trial_enabled
    case monthly_free_trial_enabled
    case yearly_free_trial_enabled
    
    // Ad configuration
    case ads_enabled
    
    case is_display_premium_after_splash
    case is_display_language_after_splash
    case distance_count_show_inter_share
    case distance_time_show_other_ads
    case distance_time_show_same_ads
    
    case inter_splash
    case inter_splash_enabled
    case inter_splash_high
    case inter_splash_high_enabled
    
    case inter_share
    case inter_share_enabled
    case inter_share_high
    case inter_share_high_enabled
    
    // GPS Camera - Native
    case native_language
    case native_language_enabled
    case native_language_high
    case native_language_high_enabled
    case native_language_click
    case native_language_click_enabled
    case native_language_click_high
    case native_language_click_high_enabled
    
    // API Configuration
    case base_url
    
    // VoiceTodo - Limit
    case max_free_usage
}

class FirebaseRemoteConfigManager: Service {
    private lazy var remoteConfig: RemoteConfig? = FirebaseApp.app() != nil ? RemoteConfig.remoteConfig() : nil
    var shouldAutostart: Bool = true
    private var hasAppliedConfig: Bool = false

    func start() {
        guard let remoteConfig else {
            print("⚠️ Firebase chưa được cấu hình, bỏ qua Remote Config, dùng giá trị mặc định")
            // Post async: at app launch time, SwiftUI views (e.g. SplashView) haven't
            // subscribed to this notification yet, so posting synchronously would be missed.
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .remoteConfigReady, object: nil)
            }
            return
        }

        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0
        remoteConfig.configSettings = settings
        
        fetchWithRetry { [weak self] success, _ in
            guard let self else { return }
            if success {
                self.applyRemoteConfig()
            }
        }
        
        // Timeout tổng thể: nếu sau 8 giây mà chưa fetch xong thì bắn notification
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            guard let self else { return }
            // Kiểm tra xem đã apply config chưa
            if !self.hasAppliedConfig {
                print("Timeout: Firebase Remote Config fetch quá lâu, sử dụng giá trị mặc định")
                NotificationCenter.default.post(name: .remoteConfigReady, object: nil)
            }
        }
    }
    
    func fetchWithRetry(
        maxRetries: Int = 2,
        baseDelay: Double = 1.0,
        completion: ((Bool, Error?) -> Void)? = nil
    ) {
        guard let remoteConfig else {
            completion?(false, nil)
            return
        }
        var attempt = 0
        
        func attemptFetch() {
            attempt += 1
            remoteConfig.fetchAndActivate { _, error in
                if error == nil {
                    print("Fetch thành công!")
                    completion?(true, nil)
                } else {
                    print("Lỗi: \(error!.localizedDescription)")
                    // backoff theo cấp số nhân
                    if attempt < maxRetries {
                        let delay = baseDelay * pow(2.0, Double(attempt - 1))
                        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                            attemptFetch()
                        }
                    } else {
                        print("Dừng retry sau \(maxRetries) lần ")
                        completion?(false, error)
                        // Bắn notification ngay cả khi fetch fail để app không bị đứng
                        NotificationCenter.default.post(name: .remoteConfigReady, object: nil)
                    }
                }
            }
        }
        
        attemptFetch()
    }
    
    // lưu dữ liệu
    private func applyRemoteConfig() {
        guard let remoteConfig else { return }
        let storage = LocalStorageService.shared
        let keychain = KeychainStorage.shared
        
        // MARK: - Subscription
        storage.monthlyFreeTrialEnabled =
        remoteConfig[FirebaseRemoteConfigKey.monthly_free_trial_enabled.rawValue].boolValue
        storage.weeklyFreeTrialEnabled =
        remoteConfig[FirebaseRemoteConfigKey.weekly_free_trial_enabled.rawValue].boolValue
        storage.yearlyFreeTrialEnabled =
        remoteConfig[FirebaseRemoteConfigKey.yearly_free_trial_enabled.rawValue].boolValue
        
        // MARK: - Ad Configurations
        
        keychain.adsEnabled = remoteConfig[FirebaseRemoteConfigKey.ads_enabled.rawValue].boolValue
        
        storage.isDisplayPremiumAfterSplash =
        remoteConfig[FirebaseRemoteConfigKey.is_display_premium_after_splash.rawValue].boolValue
        storage.isDisplayLanguageAfterSplash =
        remoteConfig[FirebaseRemoteConfigKey.is_display_language_after_splash.rawValue].boolValue
        storage.distanceCountShowInterShare =
        remoteConfig[FirebaseRemoteConfigKey.distance_count_show_inter_share.rawValue].numberValue
            .intValue
        
        storage.distanceTimeShowOtherAds =
        remoteConfig[FirebaseRemoteConfigKey.distance_time_show_other_ads.rawValue].numberValue
            .intValue
        storage.distanceTimeShowSameAds =
        remoteConfig[FirebaseRemoteConfigKey.distance_time_show_same_ads.rawValue].numberValue
            .intValue
        
        // MARK: Inter
        storage.interSplash = AdPlacement(
            id: remoteConfig[FirebaseRemoteConfigKey.inter_splash.rawValue].stringValue,
            isEnabled: remoteConfig[FirebaseRemoteConfigKey.inter_splash_enabled.rawValue]
                .boolValue
        )
        storage.interSplashHight = AdPlacement(
            id: remoteConfig[FirebaseRemoteConfigKey.inter_splash_high.rawValue].stringValue,
            isEnabled: remoteConfig[
                FirebaseRemoteConfigKey.inter_splash_high_enabled.rawValue
            ].boolValue
        )
        storage.interShare = AdPlacement(
            id: remoteConfig[FirebaseRemoteConfigKey.inter_share.rawValue].stringValue,
            isEnabled: remoteConfig[FirebaseRemoteConfigKey.inter_share_enabled.rawValue]
                .boolValue
        )
        storage.interShareHight = AdPlacement(
            id: remoteConfig[FirebaseRemoteConfigKey.inter_share_high.rawValue].stringValue,
            isEnabled: remoteConfig[FirebaseRemoteConfigKey.inter_share_high_enabled.rawValue]
                .boolValue
        )
        
        // MARK: Native
        storage.nativeLanguage = AdPlacement(
            id: remoteConfig[FirebaseRemoteConfigKey.native_language.rawValue].stringValue,
            isEnabled: remoteConfig[FirebaseRemoteConfigKey.native_language_enabled.rawValue]
                .boolValue
        )
        storage.nativeLanguageHight = AdPlacement(
            id: remoteConfig[FirebaseRemoteConfigKey.native_language_high.rawValue]
                .stringValue,
            isEnabled: remoteConfig[
                FirebaseRemoteConfigKey.native_language_high_enabled.rawValue
            ].boolValue
        )
        storage.nativeLanguageClick = AdPlacement(
            id: remoteConfig[FirebaseRemoteConfigKey.native_language_click.rawValue]
                .stringValue,
            isEnabled: remoteConfig[
                FirebaseRemoteConfigKey.native_language_click_enabled.rawValue
            ].boolValue
        )
        storage.nativeLanguageClickHight = AdPlacement(
            id: remoteConfig[FirebaseRemoteConfigKey.native_language_click_high.rawValue]
                .stringValue,
            isEnabled: remoteConfig[
                FirebaseRemoteConfigKey.native_language_click_high_enabled.rawValue
            ].boolValue
        )
        
        // MARK: - API Configuration
        let remoteBaseURL = remoteConfig[FirebaseRemoteConfigKey.base_url.rawValue].stringValue
        storage.baseURL = remoteBaseURL.isEmpty ? "" : remoteBaseURL
        
        // MARK: - VoiceTodo Limit
        storage.maxFreeUsage =
        remoteConfig[FirebaseRemoteConfigKey.max_free_usage.rawValue].numberValue.intValue
        
        // Post notification khi remote config đã được apply thành công
        hasAppliedConfig = true
        print("DEBUG: max_free_usage = \(storage.maxFreeUsage)")
        NotificationCenter.default.post(name: .remoteConfigReady, object: nil)
    }
    
    func stop() {}
}
