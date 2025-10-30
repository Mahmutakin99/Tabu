//
//  WordsCatalog.swift
//  Tabu
//
//  Created by MAHMUT AKIN on 14/10/2025.
//

import Foundation

// JSON: { "KategoriAdı": [ { "Kelime": "...", "Yasaklılar": ["...", ...] }, ... ], ... }
struct RawEntry: Decodable {
    let Kelime: String
    let Yasaklılar: [String]
}

typealias RawCatalog = [String: [RawEntry]]

enum WordProviderError: Error {
    case fileNotFound
    case decodeFailed
}

final class WordProvider {
    
    static let shared = WordProvider()
    private init() {}
    
    // Kelimeler.json'u yükle
    func loadCatalog(fileName: String = "Kelimeler") throws -> RawCatalog {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            throw WordProviderError.fileNotFound
        }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        do {
            let catalog = try decoder.decode(RawCatalog.self, from: data)
            return catalog
        } catch {
            throw WordProviderError.decodeFailed
        }
    }
    
    // Tüm kategorilerden kartlar
    func allCards() -> [Card] {
        do {
            let catalog = try loadCatalog()
            return Self.cards(from: catalog, categories: Array(catalog.keys))
        } catch {
            return []
        }
    }
    
    // Belirli kategorilerden kartlar (çoklu seçim destekler)
    func cards(forCategories categories: [String]) -> [Card] {
        do {
            let catalog = try loadCatalog()
            return Self.cards(from: catalog, categories: categories)
        } catch {
            return []
        }
    }
    
    // Tek kategori
    func cards(forCategory category: String) -> [Card] {
        return cards(forCategories: [category])
    }
    
    // Yardımcı: RawCatalog -> [Card]
    private static func cards(from catalog: RawCatalog, categories: [String]) -> [Card] {
        var result: [Card] = []
        for cat in categories {
            guard let entries = catalog[cat] else { continue }
            let cards = entries.map { Card(word: $0.Kelime, forbiddenWords: $0.Yasaklılar) }
            result.append(contentsOf: cards)
        }
        return result
    }
}

