import Foundation
import SwiftUI

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    @Published var language: String {
        didSet {
            UserDefaults.standard.set(language, forKey: "appLanguage")
        }
    }
    private var bundle: Bundle? = nil
    
    private init() {
        let saved = UserDefaults.standard.string(forKey: "appLanguage")
        if let saved = saved {
            self.language = saved
        } else if let lang = Locale.preferredLanguages.first {
            self.language = String(lang.prefix(2))
        } else {
            self.language = "en"
        }
        updateBundle()
    }
    
    func setLanguage(_ lang: String) {
        language = lang
        updateBundle()
    }
    
    private func updateBundle() {
        if let path = Bundle.main.path(forResource: language, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            self.bundle = bundle
        } else {
            self.bundle = Bundle.main
        }
        objectWillChange.send()
    }
    
    func localized(_ key: String) -> String {
        bundle?.localizedString(forKey: key, value: nil, table: nil) ?? key
    }
} 