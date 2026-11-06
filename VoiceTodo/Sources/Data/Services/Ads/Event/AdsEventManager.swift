//
//  AdsEventManager.swift
//
//  Created by Toan Nguyen on 9/24/25.
//

import Foundation

final class AdsEventManager {
    static let shared = AdsEventManager()
    
    private init() {}

    private var logger: AdsEventLogging = AdsEventLogger()
    
    func logPaidAdImpression(_ payload: PaidImpressionPayload) {
        Logger.d(messages: "paid_ad_impression", payload.adUnitId, payload.adKind.rawValue)
        
        logger.logPaidAdImpression(payload)
    }

    func logClick(_ payload: ClickPayload) {
        Logger.d(messages: "event_user_click_ads", payload.adUnitId, payload.adKind.rawValue)
        
        logger.logClick(payload)
    }
}
