# Uncomment the next line to define a global platform for your project
platform :ios, '16.0'

target 'VoiceTodo' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for VoiceTodo
  pod 'Alamofire', '~> 5.10'
  pod 'KeychainAccess', '~> 4.2'
  pod 'Google-Mobile-Ads-SDK'
  pod 'lottie-ios', '~> 4.5.2'
  pod 'Mantis', '~> 2.26'
  pod 'Kingfisher', '~> 7.0'

  # Mediation Adapters (Ví dụ các mạng phổ biến)
  pod 'GoogleMobileAdsMediationFacebook'  # Meta Audience Network
  pod 'GoogleMobileAdsMediationAppLovin'  # AppLovin
  pod 'GoogleMobileAdsMediationUnity'     # Unity Ads
  pod 'LBTATools', :git => 'https://github.com/bhlvoong/LBTATools.git'

  # Tracking (pin cứng, commit Podfile.lock) - xem ios-tracking-integration
  # Firebase Analytics qua SPM (>= 12.0). CẤM: AppsFlyer (1 MMP duy nhất = Adjust), FBSDKLoginKit/ShareKit.
  pod 'Adjust', '5.8.0'
  pod 'FBSDKCoreKit', '18.1.1'
  pod 'TikTokBusinessSDK', '1.7.2'


  # IAP
  pod 'TPInAppReceipt', '~> 3.4'

  # Firebase
  # pod 'FirebaseAnalytics', '11.2.0'
  # pod 'FirebaseCrashlytics', '11.2.0'
  # pod 'FirebaseRemoteConfig', '11.2.0'
  # pod 'FirebaseAuth', '11.2.0'

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
      # The app project uses "Dev"/"Release" instead of "Debug"/"Release", so CocoaPods
      # treats "Dev" as a release-type config by default. Force debug-style compilation
      # for "Dev" so SwiftUI Previews (which require -Onone across the dependency graph) work.
      if config.name == 'Dev'
        config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Onone'
        config.build_settings['GCC_OPTIMIZATION_LEVEL'] = '0'
        config.build_settings['SWIFT_COMPILATION_MODE'] = 'singlefile'
      end
    end
  end
end
