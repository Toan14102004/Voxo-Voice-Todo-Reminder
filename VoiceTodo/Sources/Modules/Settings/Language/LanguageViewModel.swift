//
//  LanguageViewModel.swift
//  VoiceTodo
//
//  Created by Toan Nguyen on 15/10/25.
//

import Foundation
import SwiftUI
import Combine
import FlagAndCountryCode

struct Language: Identifiable, Equatable {
    let id = UUID()
    let code: String
    let name: String
    let countryCode: String
    let flagAsset: ImageAsset
    
    static func == (lhs: Language, rhs: Language) -> Bool {
        return lhs.code == rhs.code
    }
    
    static let supportedLanguages: [Language] = [
        Language(code: "en", name: "English", countryCode: "US", flagAsset: Asset.Icon.Language.english),
        Language(code: "ja", name: "Japanese", countryCode: "JP", flagAsset: Asset.Icon.Language.japanese),
        Language(code: "es", name: "Spanish", countryCode: "ES", flagAsset: Asset.Icon.Language.spanish),
        Language(code: "fr", name: "French", countryCode: "FR", flagAsset: Asset.Icon.Language.french),
        Language(code: "hi", name: "Hindi", countryCode: "IN", flagAsset: Asset.Icon.Language.hindi),
        Language(code: "pt", name: "Portuguese", countryCode: "PT", flagAsset: Asset.Icon.Language.portuguese),
        Language(code: "de", name: "German", countryCode: "DE", flagAsset: Asset.Icon.Language.germany),
        Language(code: "ko", name: "Korean", countryCode: "KR", flagAsset: Asset.Icon.Language.korea),
        Language(code: "ar", name: "Arabic", countryCode: "SA", flagAsset: Asset.Icon.Language.arabic),
        Language(code: "bn", name: "Bengali", countryCode: "BD", flagAsset: Asset.Icon.Language.bengali),
        Language(code: "id", name: "Indonesian", countryCode: "ID", flagAsset: Asset.Icon.Language.indonesian),
        Language(code: "it", name: "Italian", countryCode: "IT", flagAsset: Asset.Icon.Language.italian),
        Language(code: "pa", name: "Punjabi", countryCode: "IN", flagAsset: Asset.Icon.Language.punjabi),
        Language(code: "ru", name: "Russian", countryCode: "RU", flagAsset: Asset.Icon.Language.russian),
        Language(code: "sw", name: "Swahili", countryCode: "TZ", flagAsset: Asset.Icon.Language.swahili),
        Language(code: "zh-Hans", name: "Chinese (Simplified)", countryCode: "CN", flagAsset: Asset.Icon.Language.chinese)
    ]
}

extension LanguageView {
    class ViewModel: BaseViewModel {

        @Navigation var navigator
        @Injected var keychainStorage: KeychainStorage
        @Injected var localStorageService: LocalStorageService
        @Injected var adsPreloadService: AdsPreloadService
        
        @Published var coordinator = Coordinator()
        @Published var languages: [Language] = Language.supportedLanguages
        @Published var selectedLanguage: Language?
        @Published var initialLanguage: Language
        @Published var hasLanguageChanged: Bool = false
        @Published var showClickAd: Bool = false
        
        let isOnboardingContext: Bool
        
        init(isOnboardingContext: Bool = false) {
            self.isOnboardingContext = isOnboardingContext
            
            let currentCode = LanguageManager.shared.currentLanguageCode
            let defaultLanguage = Language.supportedLanguages.first { $0.code == currentCode } ?? Language.supportedLanguages.first { $0.code == "en" } ?? Language.supportedLanguages[0]
            self.initialLanguage = defaultLanguage
            
            if isOnboardingContext {
                self.selectedLanguage = nil
                hasLanguageChanged = false 
            } else {
                self.selectedLanguage = defaultLanguage
                hasLanguageChanged = false  
            }
        }
        
        func goBack() {
            navigator.pop()
        }
        
        func selectLanguage(_ language: Language) {
            selectedLanguage = language
            hasLanguageChanged = true
            // Reload native ad if needed
            if showClickAd {
                let adKey: AdsPreloadService.AdsPreloadKey = .languageClick
                if let preloadedViewModel = adsPreloadService.getPreloadedAd(for: adKey),
                   !preloadedViewModel.isLoading {
                    print("[LanguageViewModel] Reloading ad \(adKey) on language selection")
                    preloadedViewModel.refreshAd()
                }
            }
            showClickAd = true
        }
        
        func confirmLanguageChange() {
            guard hasLanguageChanged, let selectedLanguage = selectedLanguage else { return }
            keychainStorage.currentLanguageCode = selectedLanguage.code
            LanguageManager.shared.changeLanguage(selectedLanguage.code)
            if isOnboardingContext {
                navigator.push(RootView.Coordinator.Navigation.content)
            } else {
                navigator.pop()
            }
        }
    }
}
