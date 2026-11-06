//
//  AppConfiguration.swift
//  VoiceTodo
//
//  Created by Toan Nguyen on 18/11/24.
//

import Foundation

enum AppConfiguration {
    static let appName = getConfigurationValue(by: .appName).unsafelyUnwrapped
    static let appEnv = getConfigurationValue(by: .appEnv).unsafelyUnwrapped
    static let appId = getConfigurationValue(by: .appId).unsafelyUnwrapped
    static let privacyUrl = getConfigurationValue(by: .privacyUrl).unsafelyUnwrapped
    static let termOfUseUrl = getConfigurationValue(by: .termOfUseUrl).unsafelyUnwrapped
    static let emailFeedback = getConfigurationValue(by: .emailFeedback).unsafelyUnwrapped
    static let adjustToken = getConfigurationValue(by: .adjustToken).unsafelyUnwrapped
    static let adjustPurchaseToken = getConfigurationValue(by: .adjustPurchaseToken) ?? ""
    static let tiktokAppId = getConfigurationValue(by: .tiktokAppId) ?? ""
    static let tiktokAccessToken = getConfigurationValue(by: .tiktokAccessToken) ?? ""

    /// App Store ID chỉ gồm số (bỏ tiền tố "id") - TikTok SDK blank im lặng nếu truyền bundle id.
    static var appStoreNumericId: String { appId.filter(\.isNumber) }

    /// Giá trị còn là placeholder `REPLACE_WITH_*` / rỗng thì coi như chưa cấu hình.
    static func isConfigured(_ value: String) -> Bool {
        !value.isEmpty && !value.hasPrefix("REPLACE_WITH")
    }
}

private extension AppConfiguration {
    enum ConfigurationValue: String {
        case appName = "APP_NAME"
        case appEnv = "APP_ENV"
        case appId = "APP_ID"
        case privacyUrl = "PRIVACY_URL"
        case termOfUseUrl = "TERM_OF_USE_URL"
        case emailFeedback = "EMAIL_FEEDBACL"
        case adjustToken = "ADJUST_TOKEN"
        case adjustPurchaseToken = "ADJUST_PURCHASE_TOKEN"
        case tiktokAppId = "TIKTOK_APP_ID"
        case tiktokAccessToken = "TIKTOK_ACCESS_TOKEN"
    }

    static func getConfigurationValue(by key: ConfigurationValue) -> String? {
        (Bundle.main.infoDictionary?[key.rawValue] as? String)?
            .replacingOccurrences(of: "\\", with: "")
    }
}
