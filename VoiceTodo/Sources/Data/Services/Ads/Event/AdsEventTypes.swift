//
//  AdsEventTypes.swift
//
//  Created by Toan Nguyen on 9/24/25.
//

import Foundation

enum AdKind: String {
    case banner = "BANNER"
    case interstitial = "INTERSTITIAL"
    case native = "NATIVE"
    case rewarded = "REWARDED"
    case appOpen = "APP_OPEN"
}

struct PaidImpressionPayload {
    let adUnitId: String
    let mediationAdapterClassName: String
    let adKind: AdKind
    /// `AdValue.value` - đã là đơn vị tiền tệ (không phải micros).
    let revenue: Double
    let precision: Int
    let currencyCode: String
    let timestampMs: Int64
}

struct ClickPayload {
    let adUnitId: String
    let adKind: AdKind
    let timestampMs: Int64
}
