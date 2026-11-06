//
//  AppDelegate.swift
//  VoiceTodo
//
//  Created by Toan Nguyen on 18/11/24.
//

import Combine
import FBSDKCoreKit
import FirebaseCore
import Foundation
import SwiftUI
import UIKit

typealias NotificationPayload = [AnyHashable: Any]
typealias FetchCompletion = (UIBackgroundFetchResult) -> Void

@MainActor
final class AppDelegate: UIResponder, UIApplicationDelegate {
    private lazy var environment = AppEnvironment.bootstrap()
    private var systemEventsHandler: SystemEventsHandler { environment.systemEventsHandler }
    private var hasPerformedDeferredStartup = false
    
    // Some SDKs (like Facebook Audience Network) expect the AppDelegate to have a window property.
    // Since we are using SwiftUI App lifecycle, we map this to the current active window.
    var window: UIWindow? {
        get { UIApplication.shared.currentUIWindow }
        set { }
    }

    var rootView: some View {
        environment.rootView
    }

    let dependencies = Dependencies {
        Dependency { LocalStorageService() }
        Dependency { KeychainStorage() }
        Dependency { NetworkService() }
        Dependency { FileStorageManager() }
        Dependency { OnDemandResourceService() }
        Dependency { DatabaseService.createDefault() }
        Dependency { FirebaseRemoteConfigManager() }
        Dependency { SubscriptionManager() }
        Dependency { AdsManager() }
        Dependency { AdsPreloadService() }
        Dependency { LoadingService() }
        Dependency { FirebaseAnalyticsService() }
        Dependency { RealUserPermissionsInteractor(openAppSettings: {
            URL(string: UIApplication.openSettingsURLString).flatMap {
                UIApplication.shared.open($0, options: [:], completionHandler: nil)
            }
        }) }
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Thứ tự bắt buộc: Firebase -> Meta ApplicationDelegate -> TrackingKit (mọi launch, không gate).
        firebaseConfig()
        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
        TrackingKit.shared.start()

        // Chỉ ads SDK bị gate bởi consent; lần đầu sẽ start sau khi UMP xong ở Splash.
        GoogleMobileAdsConsentManager.shared.startMobileAdsIfAllowed()

        dependencies.build()
        dependencies
            .compactMap { $0 as? Service }
            .filter(\.shouldAutostart)
            .forEach { $0.start() }
        
        let savedLanguage = KeychainStorage.shared.currentLanguageCode
        LanguageManager.shared.initialize(savedLanguageCode: savedLanguage)

        return true
    }

    func application(_: UIApplication, supportedInterfaceOrientationsFor _: UIWindow?) -> UIInterfaceOrientationMask {
        .portrait
    }

    func application(
        _: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options _: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let sceneConfig = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        sceneConfig.delegateClass = SceneDelegate.self
        SceneDelegate.register(systemEventsHandler)
        return sceneConfig
    }

    func applicationDidBecomeActive(_: UIApplication) {
        guard hasPerformedDeferredStartup == false else { return }
        hasPerformedDeferredStartup = true

        // Compute services on the main thread to avoid capturing non-Sendable container in the background closure
        let servicesToStart: [Service] = dependencies
            .compactMap { $0 as? Service }
            .filter(\.shouldAutostart)

        // Start services after first frame on main queue to avoid Sendable warnings
        // Each service should handle its own internal threading if needed
        DispatchQueue.main.async { [servicesToStart] in
            servicesToStart.forEach { $0.start() }
        }
    }

    func application(_: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        systemEventsHandler.handlePushRegistration(result: .success(deviceToken))
    }

    func application(_: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        systemEventsHandler.handlePushRegistration(result: .failure(error))
    }

    func application(
        _: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any]
    ) async -> UIBackgroundFetchResult {
        await systemEventsHandler.appDidReceiveRemoteNotification(payload: userInfo)
    }

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        ApplicationDelegate.shared.application(
            app,
            open: url,
            sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
            annotation: options[UIApplication.OpenURLOptionsKey.annotation]
        )
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        systemEventsHandler.applicationWillTerminate()
    }
}

// MARK: Firebase config

private extension AppDelegate {
    func firebaseConfig() {
        guard let filePath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let options = FirebaseOptions(contentsOfFile: filePath) else {
            fatalError("Not found GoogleService-Info.plist")
        }

        guard options.apiKey?.hasPrefix("REPLACE_WITH_") == false else {
            print("⚠️ GoogleService-Info.plist chưa được cấu hình với project Firebase thật, bỏ qua FirebaseApp.configure().")
            return
        }

        FirebaseApp.configure(options: options)
    }
}
