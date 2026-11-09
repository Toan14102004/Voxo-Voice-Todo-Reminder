//
//  LanguageManager.swift
//  VoiceTodo
//
//  Created by Assistant on 8/9/25.
//

import Foundation
import SwiftUI

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    /// Language codes the app ships translations for (must match `Language.supportedLanguages`).
    static let supportedCodes = ["en", "vi", "ja", "es", "fr", "hi", "pt", "de", "ko", "ar", "bn", "id", "it", "pa", "ru", "sw", "zh-Hans"]

    /// Maps a system/locale language code to a supported one, falling back to English.
    static func resolve(_ code: String) -> String {
        if supportedCodes.contains(code) { return code }
        let base = code.split(separator: "-").first.map(String.init) ?? code
        if base == "zh" { return "zh-Hans" }
        return supportedCodes.contains(base) ? base : "en"
    }

    /// Right-to-left for Arabic etc., so SwiftUI mirrors the layout.
    var layoutDirection: LayoutDirection {
        Locale.Language(identifier: currentLanguageCode).characterDirection == .rightToLeft ? .rightToLeft : .leftToRight
    }

    @Published var currentLocale: Locale
    @Published var currentLanguageCode: String = ""

    private init() {
        currentLanguageCode = "en"
        currentLocale = Locale.current
    }
    
    func initialize(savedLanguageCode: String) {
        if savedLanguageCode.isEmpty {
            currentLanguageCode = Self.resolve(Locale.current.language.languageCode?.identifier ?? "en")
            currentLocale = Locale(identifier: currentLanguageCode)
        } else {
            currentLanguageCode = Self.resolve(savedLanguageCode)
            currentLocale = Locale(identifier: currentLanguageCode)
        }
    }
    
    func changeLanguage(_ languageCode: String) {
        currentLanguageCode = languageCode
        currentLocale = Locale(identifier: languageCode)
        
        // Trigger UI refresh
        objectWillChange.send()
    }
}
