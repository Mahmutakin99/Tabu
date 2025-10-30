//
//  SettingsManager.swift
//  Tabu
//
//  Created by MAHMUT AKIN on 14/10/2025.
//

import Foundation

final class SettingsManager {
    static let shared = SettingsManager()
    private init() {}
    
    private let selectedCategoriesKey = "selectedCategories"
    
    // Çoklu kategori seçimi
    var selectedCategories: [String]? {
        get {
            UserDefaults.standard.stringArray(forKey: selectedCategoriesKey)
        }
        set {
            if let arr = newValue {
                UserDefaults.standard.set(arr, forKey: selectedCategoriesKey)
            } else {
                UserDefaults.standard.removeObject(forKey: selectedCategoriesKey)
            }
        }
    }
    
    // Oyun başlarken kullanılacak kartlar
    func provideCards() -> [Card] {
        // Seçim yoksa tüm katalog
        if let selected = selectedCategories, selected.isEmpty == false {
            return WordProvider.shared.cards(forCategories: selected)
        } else {
            return WordProvider.shared.allCards()
        }
    }
}

