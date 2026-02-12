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
    private let selectedDifficultiesKey = "selectedDifficulties"
    private let cacheQueue = DispatchQueue(label: "SettingsManager.cache.queue", qos: .userInitiated)
    private let maxSelectionCacheEntries = 16
    
    private struct SelectionCacheKey: Hashable {
        let categories: [String]
        let difficulties: [CardDifficulty]
        
        init(categories: Set<String>, difficulties: Set<CardDifficulty>) {
            self.categories = categories.sorted()
            self.difficulties = difficulties.sorted { $0.rawValue < $1.rawValue }
        }
    }
    
    private var cachedBySelection: [SelectionCacheKey: [Card]] = [:]
    private var cachedSelectionOrder: [SelectionCacheKey] = []
    
    // Çoklu kategori seçimi
    var selectedCategories: [String]? {
        get {
            UserDefaults.standard.stringArray(forKey: selectedCategoriesKey)
        }
        set {
            if let arr = newValue {
                let unique = Array(Set(arr)).sorted()
                UserDefaults.standard.set(unique, forKey: selectedCategoriesKey)
            } else {
                UserDefaults.standard.removeObject(forKey: selectedCategoriesKey)
            }
            invalidateCache()
        }
    }
    
    // Çoklu zorluk seçimi
    var selectedDifficulties: [CardDifficulty]? {
        get {
            guard let rawValues = UserDefaults.standard.stringArray(forKey: selectedDifficultiesKey) else {
                return nil
            }
            let parsed = Set(rawValues.compactMap { CardDifficulty(rawValue: $0.lowercased()) })
            return parsed.isEmpty ? nil : parsed.sorted { $0.rawValue < $1.rawValue }
        }
        set {
            if let values = newValue {
                let raw = Set(values).map(\.rawValue).sorted()
                UserDefaults.standard.set(raw, forKey: selectedDifficultiesKey)
            } else {
                UserDefaults.standard.removeObject(forKey: selectedDifficultiesKey)
            }
            invalidateCache()
        }
    }
    
    var effectiveSelectedDifficulties: Set<CardDifficulty> {
        guard let selected = selectedDifficulties, selected.isEmpty == false else {
            return Set(CardDifficulty.allCases)
        }
        return Set(selected)
    }
    
    // Oyun başlarken kullanılacak kartlar
    func provideCards() -> [Card] {
        let categories = Set(selectedCategories ?? [])
        let difficulties = effectiveSelectedDifficulties
        let cacheKey = SelectionCacheKey(categories: categories, difficulties: difficulties)
        
        if let cached = cacheQueue.sync(execute: { cachedBySelection[cacheKey] }) {
            return cached
        }
        
        let cards: [Card]
        if categories.isEmpty {
            cards = WordProvider.shared.allCards(difficulties: difficulties)
        } else {
            cards = WordProvider.shared.cards(forCategories: Array(categories), difficulties: difficulties)
        }
        
        let safeCards: [Card]
        if cards.isEmpty == false {
            safeCards = cards
        } else {
            // Geçersiz bir kombinasyon seçildiyse oyunu boş bırakma.
            let fallback = WordProvider.shared.allCards(difficulties: difficulties)
            safeCards = fallback.isEmpty ? WordProvider.shared.allCards(difficulties: Set(CardDifficulty.allCases)) : fallback
        }
        
        cacheQueue.sync {
            cachedBySelection[cacheKey] = safeCards
            cachedSelectionOrder.append(cacheKey)
            if cachedSelectionOrder.count > maxSelectionCacheEntries {
                let removed = cachedSelectionOrder.removeFirst()
                cachedBySelection.removeValue(forKey: removed)
            }
        }
        return safeCards
    }
    
    private func invalidateCache() {
        cacheQueue.sync {
            cachedBySelection.removeAll()
            cachedSelectionOrder.removeAll()
        }
    }
}
