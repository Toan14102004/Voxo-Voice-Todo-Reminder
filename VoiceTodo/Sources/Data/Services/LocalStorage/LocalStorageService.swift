//
//  LocalStorageService.swift
//  VoiceTodo
//
//  Created by Toan Nguyen on 18/11/24.
//

import Foundation

protocol UserDefaultService: AnyObject {
    // App flags
    var isFirstTimeOpenApp: Bool { get set }
    var isFirstTimeUsingApp: Bool { get set }
    
    // Subscription
    var weeklyFreeTrialEnabled: Bool { get set }
    var monthlyFreeTrialEnabled: Bool { get set }
    var yearlyFreeTrialEnabled: Bool { get set }
    
    // Global Ad Config
    var isDisplayPremiumAfterSplash: Bool { get set }
    var isDisplayLanguageAfterSplash: Bool { get set }
    var distanceCountShowInterShare: Int { get set }
    var distanceTimeShowOtherAds: Int { get set }
    var distanceTimeShowSameAds: Int { get set }
    
    // VoiceTodo - Inter
    var interSplash: AdPlacement { get set }
    var interSplashHight: AdPlacement { get set }
    var interShare: AdPlacement { get set }
    var interShareHight: AdPlacement { get set }
    
    // VoiceTodo - Native
    var nativeLanguage: AdPlacement { get set }
    var nativeLanguageClick: AdPlacement { get set }
    var nativeLanguageClickHight: AdPlacement { get set }
    var nativeLanguageHight: AdPlacement { get set }
    
    // API Configuration
    var baseURL: String { get set }
    
    // VoiceTodo - Limit
    // var countUsage: Int { get set }
    var maxFreeUsage: Int { get set }
}

private enum Keys {
    // App flags
    static let isFirstTimeOpenApp = "isFirstTimeOpenApp"
    static let isFirstTimeUsingApp = "isFirstTimeUsingApp"
    
    // Subscription
    static let monthlyFreeTrialEnabled = "monthly_free_trial_enabled"
    static let weeklyFreeTrialEnabled = "weekly_free_trial_enabled"
    static let yearlyFreeTrialEnabled = "yearly_free_trial_enabled"
    
    // Global Ad Config
    static let isDisplayPremiumAfterSplash = "isDisplayPremiumAfterSplash"
    static let isDisplayLanguageAfterSplash = "is_display_language_after_splash"
    static let distanceCountShowInterShare = "distance_count_show_inter_share"
    static let distanceTimeShowOtherAds = "distance_time_show_other_ads"
    static let distanceTimeShowSameAds = "distance_time_show_same_ads"
    
    // VoiceTodo - Inter
    static let interSplash = "inter_splash"
    static let interSplashHight = "inter_splash_high"
    static let interShare = "inter_share"
    static let interShareHight = "inter_share_high"
    
    // VoiceTodo - Native
    static let nativeLanguage = "native_language"
    static let nativeLanguageHight = "native_language_high"
    static let nativeLanguageClick = "native_language_click"
    static let nativeLanguageClickHight = "native_language_click_high"
    
    // API Configuration
    static let baseURL = "base_url"
    
    // VoiceTodo - Limit
    static let maxFreeUsage = "max_free_usage"
}

class LocalStorageService: UserDefaultService {
    static let shared = LocalStorageService()
    
    @ObjectUserDefaultWrapper(key: Keys.isFirstTimeOpenApp, defaultValue: true)
    var isFirstTimeOpenApp: Bool
    
    @ObjectUserDefaultWrapper(key: Keys.isFirstTimeUsingApp, defaultValue: true)
    var isFirstTimeUsingApp: Bool
    
    // MARK: - Subscription
    @UserDefaultWrapper(key: Keys.weeklyFreeTrialEnabled, defaultValue: true)
    var weeklyFreeTrialEnabled: Bool
    
    @UserDefaultWrapper(key: Keys.monthlyFreeTrialEnabled, defaultValue: false)
    var monthlyFreeTrialEnabled: Bool
    
    @UserDefaultWrapper(key: Keys.yearlyFreeTrialEnabled, defaultValue: false)
    var yearlyFreeTrialEnabled: Bool
    
    // MARK: Global Ad config
    @ObjectUserDefaultWrapper(key: Keys.isDisplayPremiumAfterSplash, defaultValue: true)
    var isDisplayPremiumAfterSplash: Bool
    
    @UserDefaultWrapper(key: Keys.isDisplayLanguageAfterSplash, defaultValue: true)
    var isDisplayLanguageAfterSplash: Bool
    
    @UserDefaultWrapper(key: Keys.distanceCountShowInterShare, defaultValue: 3)
    var distanceCountShowInterShare: Int
    
    @UserDefaultWrapper(key: Keys.distanceTimeShowOtherAds, defaultValue: 20)
    var distanceTimeShowOtherAds: Int
    
    @UserDefaultWrapper(key: Keys.distanceTimeShowSameAds, defaultValue: 20)
    var distanceTimeShowSameAds: Int
    
    // MARK: - API Configuration
    @UserDefaultWrapper(
        key: Keys.baseURL, defaultValue: "https://api.example.com")
    var baseURL: String
    
    // MARK: - VoiceTodo Ad Placements
    
    // Inter
    @ObjectUserDefaultWrapper(
        key: Keys.interSplash,
        defaultValue: AdPlacement(id: "ca-app-pub-3940256099942544/1033173712", isEnabled: true)
    )
    var interSplash: AdPlacement
    
    @ObjectUserDefaultWrapper(
        key: Keys.interSplashHight,
        defaultValue: AdPlacement(id: "ca-app-pub-3940256099942544/1033173712", isEnabled: true)
    )
    var interSplashHight: AdPlacement
    
    @ObjectUserDefaultWrapper(
        key: Keys.interShare,
        defaultValue: AdPlacement(id: "ca-app-pub-3940256099942544/1033173712", isEnabled: true)
    )
    var interShare: AdPlacement
    
    @ObjectUserDefaultWrapper(
        key: Keys.interShareHight,
        defaultValue: AdPlacement(id: "ca-app-pub-3940256099942544/1033173712", isEnabled: true)
    )
    var interShareHight: AdPlacement
    
    // Inter
    @ObjectUserDefaultWrapper(
        key: Keys.nativeLanguage,
        defaultValue: AdPlacement(id: "ca-app-pub-3940256099942544/2247696110", isEnabled: true)
    )
    var nativeLanguage: AdPlacement
    
    @ObjectUserDefaultWrapper(
        key: Keys.nativeLanguageHight,
        defaultValue: AdPlacement(id: "ca-app-pub-3940256099942544/2247696110", isEnabled: true)
    )
    var nativeLanguageHight: AdPlacement
    
    @ObjectUserDefaultWrapper(
        key: Keys.nativeLanguageClick,
        defaultValue: AdPlacement(id: "ca-app-pub-3940256099942544/2247696110", isEnabled: true)
    )
    var nativeLanguageClick: AdPlacement
    
    @ObjectUserDefaultWrapper(
        key: Keys.nativeLanguageClickHight,
        defaultValue: AdPlacement(id: "ca-app-pub-3940256099942544/2247696110", isEnabled: true)
    )
    var nativeLanguageClickHight: AdPlacement
    
    // MARK: - VoiceTodo Limit
    @UserDefaultWrapper(key: Keys.maxFreeUsage, defaultValue: 3)
    var maxFreeUsage: Int
}
