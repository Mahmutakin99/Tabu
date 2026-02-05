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
    
    private var cachedAllCards: [Card]? = nil
    private var cachedByCategories: [Set<String>: [Card]] = [:]
    
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
            invalidateCache()
        }
    }
    
    // Oyun başlarken kullanılacak kartlar
    func provideCards() -> [Card] {
        // Seçim yoksa tüm katalog (cache)
        if let selected = selectedCategories, selected.isEmpty == false {
            let key = Set(selected)
            if let cached = cachedByCategories[key] {
                return cached
            }
            let cards = WordProvider.shared.cards(forCategories: selected)
            cachedByCategories[key] = cards
            return cards
        } else {
            if let cached = cachedAllCards { return cached }
            let cards = WordProvider.shared.allCards()
            cachedAllCards = cards
            return cards
        }
    }
    
    private func invalidateCache() {
        cachedAllCards = nil
        cachedByCategories.removeAll()
    }
}

