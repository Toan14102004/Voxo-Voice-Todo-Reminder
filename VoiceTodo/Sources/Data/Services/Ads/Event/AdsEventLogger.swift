//
//  AdsEventLogger.swift
//
//  Created by Toan Nguyen on 9/24/25.
//

import FBSDKCoreKit
import Foundation

protocol AdsEventLogging {
    func logPaidAdImpression(_ payload: PaidImpressionPayload)
    func logClick(_ payload: ClickPayload)
}

final class AdsEventLogger: AdsEventLogging {
    /// Ad revenue chỉ đi qua `TrackingKit.handleAdPaidEvent` (Adjust / Meta / TikTok / Google theo profile).
    func logPaidAdImpression(_ payload: PaidImpressionPayload) {
        TrackingKit.shared.handleAdPaidEvent(
            network: payload.mediationAdapterClassName,
            amount: payload.revenue,
            currency: payload.currencyCode,
            precision: payload.precision,
            adUnitId: payload.adUnitId
        )
    }

    func logClick(_ payload: ClickPayload) {
        AppEvents.shared.logEvent(
            .adClick,
            parameters: [
                AppEvents.ParameterName("ad_unit_id"): payload.adUnitId,
                AppEvents.ParameterName("ad_kind"): payload.adKind.rawValue,
                AppEvents.ParameterName("timestamp_ms"): payload.timestampMs
            ]
        )
    }
}
