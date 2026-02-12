//
//  WordsCatalog.swift
//  Tabu
//
//  Created by MAHMUT AKIN on 14/10/2025.
//

import Foundation

// JSON: { "KategoriAdı": [ { "Kelime": "...", "Yasaklılar": ["...", ...], "Zorluk": "easy|medium|hard" }, ... ], ... }
struct RawEntry: Decodable {
    let Kelime: String
    let Yasaklılar: [String]
    let Zorluk: String?
}

typealias RawCatalog = [String: [RawEntry]]

enum WordProviderError: Error {
    case fileNotFound
    case decodeFailed
}

final class WordProvider {
    
    static let shared = WordProvider()
    
    private struct CardsCacheKey: Hashable {
        let categories: [String]
        let difficulties: [CardDifficulty]
        
        init(categories: Set<String>, difficulties: Set<CardDifficulty>) {
            self.categories = categories.sorted()
            self.difficulties = difficulties.sorted { $0.rawValue < $1.rawValue }
        }
    }
    
    private let fileName = "Kelimeler"
    private let cacheQueue = DispatchQueue(label: "WordProvider.cache.queue", qos: .userInitiated)
    private let loadLock = NSLock()
    private let maxCardsCacheEntries = 24
    private let genericForbiddenTokens: Set<String> = ["temel", "gelişmiş", "profesyonel", "yeni nesil"]
    private let sensitiveTokens: Set<String> = ["porn", "porno", "pornographic", "sexual", "sex", "nude", "whore", "erotic", "shit", "fuck"]
    
    private var cachedCatalog: RawCatalog?
    private var cachedCategories: [String]?
    private var cachedCards: [CardsCacheKey: [Card]] = [:]
    private var cachedCardsOrder: [CardsCacheKey] = []
    
    private init() {}
    
    func preloadCatalogIfNeeded() {
        _ = try? loadCatalog()
    }
    
    func categories() -> [String] {
        if let cached = cacheQueue.sync(execute: { cachedCategories }) {
            return cached
        }
        do {
            let catalog = try loadCatalog()
            return Array(catalog.keys).sorted()
        } catch {
            return []
        }
    }
    
    // Kelimeler.json'u yükle (bellek cache)
    func loadCatalog() throws -> RawCatalog {
        if let cached = cacheQueue.sync(execute: { cachedCatalog }) {
            return cached
        }
        
        loadLock.lock()
        defer { loadLock.unlock() }
        
        if let cached = cacheQueue.sync(execute: { cachedCatalog }) {
            return cached
        }
        
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            throw WordProviderError.fileNotFound
        }
        
        let data = try Data(contentsOf: url, options: .mappedIfSafe)
        let decoder = JSONDecoder()
        
        do {
            let catalog = try decoder.decode(RawCatalog.self, from: data)
            cacheQueue.sync {
                cachedCatalog = catalog
                cachedCategories = Array(catalog.keys).sorted()
                cachedCards.removeAll(keepingCapacity: true)
                cachedCardsOrder.removeAll(keepingCapacity: true)
            }
            return catalog
        } catch {
            throw WordProviderError.decodeFailed
        }
    }
    
    // Tüm kategorilerden kartlar
    func allCards(difficulties: Set<CardDifficulty> = Set(CardDifficulty.allCases)) -> [Card] {
        do {
            let catalog = try loadCatalog()
            return cards(from: catalog, categories: Set(catalog.keys), difficulties: effectiveDifficulties(from: difficulties))
        } catch {
            return []
        }
    }
    
    // Belirli kategorilerden kartlar (çoklu seçim destekler)
    func cards(forCategories categories: [String],
               difficulties: Set<CardDifficulty> = Set(CardDifficulty.allCases)) -> [Card] {
        do {
            let catalog = try loadCatalog()
            let effectiveCategories = categories.isEmpty ? Set(catalog.keys) : Set(categories)
            return cards(from: catalog,
                         categories: effectiveCategories,
                         difficulties: effectiveDifficulties(from: difficulties))
        } catch {
            return []
        }
    }
    
    // Tek kategori
    func cards(forCategory category: String,
               difficulties: Set<CardDifficulty> = Set(CardDifficulty.allCases)) -> [Card] {
        return cards(forCategories: [category], difficulties: difficulties)
    }
    
    private func effectiveDifficulties(from input: Set<CardDifficulty>) -> Set<CardDifficulty> {
        input.isEmpty ? Set(CardDifficulty.allCases) : input
    }
    
    // Yardımcı: RawCatalog -> [Card]
    private func cards(from catalog: RawCatalog,
                       categories: Set<String>,
                       difficulties: Set<CardDifficulty>) -> [Card] {
        let cacheKey = CardsCacheKey(categories: categories, difficulties: difficulties)
        
        if let cached = cacheQueue.sync(execute: { cachedCards[cacheKey] }) {
            return cached
        }
        
        var result: [Card] = []
        for category in categories.sorted() {
            guard let entries = catalog[category] else { continue }
            for entry in entries {
                let trimmedWord = entry.Kelime.trimmingCharacters(in: .whitespacesAndNewlines)
                let normalizedWord = normalizeToken(trimmedWord)
                guard trimmedWord.isEmpty == false, normalizedWord.isEmpty == false else { continue }
                guard isValidWord(trimmedWord, normalized: normalizedWord) else { continue }
                
                let forbiddenWords = sanitizeForbiddenWords(entry.Yasaklılar, normalizedWord: normalizedWord)
                guard forbiddenWords.count == 5 else { continue }
                
                let difficulty = CardDifficulty(rawValue: entry.Zorluk?.lowercased() ?? "") ?? .medium
                guard difficulties.contains(difficulty) else { continue }
                
                result.append(Card(word: trimmedWord,
                                   forbiddenWords: forbiddenWords,
                                   difficulty: difficulty))
            }
        }
        
        cacheQueue.sync {
            cachedCards[cacheKey] = result
            cachedCardsOrder.append(cacheKey)
            if cachedCardsOrder.count > maxCardsCacheEntries {
                let removed = cachedCardsOrder.removeFirst()
                cachedCards.removeValue(forKey: removed)
            }
        }
        return result
    }
    
    private func sanitizeForbiddenWords(_ rawWords: [String], normalizedWord: String) -> [String] {
        var seen: Set<String> = []
        var result: [String] = []
        
        for raw in rawWords {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            let normalized = normalizeToken(trimmed)
            guard trimmed.isEmpty == false, normalized.isEmpty == false else { continue }
            guard normalized != normalizedWord else { continue }
            guard isBlockedToken(normalized) == false else { continue }
            guard seen.insert(normalized).inserted else { continue }
            
            result.append(trimmed)
            if result.count == 5 { break }
        }
        
        if result.count < 5 {
            for raw in rawWords {
                let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
                let normalized = normalizeToken(trimmed)
                guard trimmed.isEmpty == false, normalized.isEmpty == false else { continue }
                guard normalized != normalizedWord else { continue }
                guard isBlockedToken(normalized) == false else { continue }
                guard seen.insert(normalized).inserted else { continue }
                
                result.append(trimmed)
                if result.count == 5 { break }
            }
        }
        
        return Array(result.prefix(5))
    }
    
    private func isValidWord(_ word: String, normalized: String) -> Bool {
        guard word.count <= 64 else { return false }
        guard isBlockedToken(normalized) == false else { return false }
        let tokenCount = word.split(whereSeparator: { $0.isWhitespace }).count
        return tokenCount <= 9
    }
    
    private func isBlockedToken(_ normalized: String) -> Bool {
        if genericForbiddenTokens.contains(normalized) {
            return true
        }
        return sensitiveTokens.contains { token in
            normalized == token ||
                normalized.hasPrefix("\(token) ") ||
                normalized.hasSuffix(" \(token)") ||
                normalized.contains(" \(token) ")
        }
    }
    
    private func normalizeToken(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9\\s]", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
