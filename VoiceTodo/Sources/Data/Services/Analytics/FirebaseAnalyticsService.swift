//
//  FirebaseAnalyticsService.swift
//  VoiceTodo
//
//  Created by Auto on 11/2/25.
//

import Foundation
import FirebaseAnalytics

enum AnalyticsParameterKey {
    static let screen = "screen"
    static let step = "step"
    static let fromStep = "fromStep"
    static let template = "template"
    static let hasLocation = "hasLocation"
    static let status = "status"
    static let result = "result"
    static let mediaType = "mediaType"
    static let reason = "reason"
    static let source = "source"
    static let mediaId = "mediaId"
    static let itemId = "itemId"
    static let tool = "tool"
    static let placement = "placement"
    static let next = "next"
    static let query = "query"
    static let language = "language"
    static let destination = "destination"
    static let productId = "productId"
    static let style = "style"
    static let type = "type"
    static let answer = "answer"
    static let hasText = "hasText"
    static let latitude = "latitude"
    static let longitude = "longitude"
    static let locationId = "locationId"
    static let videoId = "videoId"
    static let isEnabled = "isEnabled"
    static let decision = "decision"
    static let fromSplash = "fromSplash"
    static let isOnboarding = "isOnboarding"
}

class FirebaseAnalyticsService: Service {
    var shouldAutostart: Bool { true }
    
    func start() {
        // Service tự động start khi app launch
        // Firebase Analytics đã được configure trong AppDelegate
    }
    
    func stop() {
        // Không cần cleanup cho Firebase Analytics
    }
    
    // MARK: - Screen Tracking
    
    /// Track screen view với tên màn hình
    /// - Parameters:
    ///   - name: Tên màn hình (ví dụ: "home_screen")
    ///   - parameters: Các tham số bổ sung (optional)
    func trackScreen(name: String, parameters: [String: Any]? = nil) {
        var screenParameters: [String: Any] = [
            AnalyticsParameterScreenName: name,
            AnalyticsParameterScreenClass: name
        ]
        
        if let parameters = parameters {
            screenParameters.merge(parameters) { (_, new) in new }
        }
        
        Analytics.logEvent(AnalyticsEventScreenView, parameters: screenParameters)
    }
    
    // MARK: - Event Tracking
    
    /// Track custom event
    /// - Parameters:
    ///   - name: Tên event
    ///   - parameters: Các tham số của event
    func trackEvent(name: String, parameters: [String: Any]? = nil) {
        Analytics.logEvent(name, parameters: parameters)
    }

    /// Preferred helper for logging analytics events.
    /// Keeps naming consistent with Firebase terminology while allowing
    /// future custom behavior (sampling, extra metadata, etc.)
    func logEvent(name: String, parameters: [String: Any]? = nil) {
        trackEvent(name: name, parameters: parameters)
    }
}

