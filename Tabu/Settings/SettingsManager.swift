//
//  SettingsManager.swift
//  Tabu
//
//  Created by MAHMUT AKIN on 14/10/2025.
//

import Foundation

struct CardSelection: Hashable {
    let categories: Set<String>
    let difficulties: Set<CardDifficulty>
    
    init(categories: Set<String>, difficulties: Set<CardDifficulty>) {
        self.categories = categories
        self.difficulties = difficulties.isEmpty ? Set(CardDifficulty.allCases) : difficulties
    }
    
    init(categories: [String], difficulties: [CardDifficulty]) {
        self.init(categories: Set(categories), difficulties: Set(difficulties))
    }
}

final class SettingsManager {
    static let shared = SettingsManager()
    private init() {}
    
    private let selectedCategoriesKey = "selectedCategories"
    private let selectedDifficultiesKey = "selectedDifficulties"
    
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
        }
    }
    
    var effectiveSelectedDifficulties: Set<CardDifficulty> {
        guard let selected = selectedDifficulties, selected.isEmpty == false else {
            return Set(CardDifficulty.allCases)
        }
        return Set(selected)
    }
    
    func currentSelection() -> CardSelection {
        CardSelection(
            categories: Set(selectedCategories ?? []),
            difficulties: effectiveSelectedDifficulties
        )
    }
    
    func availableCardCount(for selection: CardSelection) -> Int {
        WordProvider.shared.availableCount(for: selection)
    }
    
    func provideCards(for selection: CardSelection) -> [Card] {
        WordProvider.shared.cards(for: selection)
    }
    
    // Oyun başlarken kullanılacak kartlar
    func provideCards() -> [Card] {
        provideCards(for: currentSelection())
    }
}
