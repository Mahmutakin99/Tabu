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
    
    private struct CatalogState {
        let categories: [String]
        let allCards: [Card]
        let cardsByCategory: [String: [Card]]
    }
    
    private struct CardsCacheKey: Hashable {
        let categories: [String]
        let difficulties: [CardDifficulty]
        
        init(categories: Set<String>, difficulties: Set<CardDifficulty>) {
            self.categories = categories.sorted()
            self.difficulties = difficulties.sorted { $0.rawValue < $1.rawValue }
        }
    }
    
    private struct CatalogDiagnostics {
        var totalEntries: Int = 0
        var rejectedWord: Int = 0
        var rejectedForbidden: Int = 0
        var unknownDifficulty: Int = 0
    }
    
    private let fileName = "Kelimeler"
    private let prepQueue = DispatchQueue(label: "WordProvider.prep.queue", qos: .utility, attributes: .concurrent)
    private let cacheQueue = DispatchQueue(label: "WordProvider.cache.queue", qos: .userInitiated)
    private let loadLock = NSLock()
    private let maxCardsCacheEntries = 24
    private let genericForbiddenTokens: Set<String> = ["temel", "gelişmiş", "profesyonel", "yeni nesil"]
    private let sensitiveTokens: Set<String> = ["porn", "porno", "pornographic", "sexual", "sex", "nude", "whore", "erotic", "shit", "fuck"]
    
    private let categoryFallbackTokens: [String: [String]] = [
        "Diziler & Filmler": ["film", "dizi", "oyuncu", "yönetmen", "karakter", "sahne", "senaryo", "kamera", "kurgu"],
        "Astronomi, Fizik & Mühendislik": ["uzay", "yıldız", "gezegen", "fizik", "mühendislik", "enerji", "deney", "kuvvet", "teori"],
        "Spor": ["spor", "maç", "takım", "skor", "oyuncu", "turnuva", "antrenman", "saha", "hakem"],
        "Tarih": ["tarih", "savaş", "antlaşma", "imparatorluk", "medeniyet", "dönem", "olay", "kronoloji", "belge"],
        "Coğrafya": ["coğrafya", "kıta", "ülke", "şehir", "dağ", "nehir", "ada", "iklim", "harita"],
        "Müzik": ["müzik", "ritim", "melodi", "nota", "enstrüman", "konser", "albüm", "şarkı", "sanatçı"],
        "Teknoloji": ["teknoloji", "yazılım", "donanım", "sistem", "ağ", "veri", "cihaz", "uygulama", "algoritma"],
        "Yemek": ["yemek", "tarif", "mutfak", "malzeme", "lezzet", "baharat", "sos", "pişirme", "tatlı"],
        "Doğa": ["doğa", "orman", "canlı", "bitki", "hayvan", "ekosistem", "habitat", "iklim", "çevre"],
        "Sanat": ["sanat", "eser", "galeri", "sergi", "müze", "resim", "heykel", "estetik", "kompozisyon"]
    ]
    
    private var cachedState: CatalogState?
    private var cachedCategories: [String]?
    private var cachedCards: [CardsCacheKey: [Card]] = [:]
    private var cachedCardsOrder: [CardsCacheKey] = []
    
    private init() {}
    
    func preloadCatalogIfNeeded() {
        _ = loadStateIfNeeded()
    }
    
    func warmupIfNeeded(completion: @escaping () -> Void) {
        prepQueue.async { [weak self] in
            _ = self?.loadStateIfNeeded()
            DispatchQueue.main.async {
                completion()
            }
        }
    }
    
    func categories() -> [String] {
        if let cached = cacheQueue.sync(execute: { cachedCategories }) {
            return cached
        }
        return loadStateIfNeeded()?.categories ?? []
    }
    
    // Tüm kategorilerden kartlar
    func allCards(difficulties: Set<CardDifficulty> = Set(CardDifficulty.allCases)) -> [Card] {
        cards(for: CardSelection(categories: [], difficulties: difficulties))
    }
    
    // Belirli kategorilerden kartlar (çoklu seçim destekler)
    func cards(forCategories categories: [String],
               difficulties: Set<CardDifficulty> = Set(CardDifficulty.allCases)) -> [Card] {
        cards(for: CardSelection(categories: Set(categories), difficulties: difficulties))
    }
    
    // Tek kategori
    func cards(forCategory category: String,
               difficulties: Set<CardDifficulty> = Set(CardDifficulty.allCases)) -> [Card] {
        return cards(forCategories: [category], difficulties: difficulties)
    }
    
    func cards(for selection: CardSelection) -> [Card] {
        guard let state = loadStateIfNeeded() else { return [] }
        
        let categories = selection.categories.isEmpty ? Set(state.categories) : selection.categories
        let difficulties = effectiveDifficulties(from: selection.difficulties)
        let cacheKey = CardsCacheKey(categories: categories, difficulties: difficulties)
        
        if let cached = cacheQueue.sync(execute: { cachedCards[cacheKey] }) {
            return cached
        }
        
        var result: [Card] = []
        result.reserveCapacity(state.allCards.count)
        
        for category in categories.sorted() {
            guard let cards = state.cardsByCategory[category] else { continue }
            for card in cards where difficulties.contains(card.difficulty) {
                result.append(card)
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
    
    func availableCount(for selection: CardSelection) -> Int {
        cards(for: selection).count
    }
    
    private func effectiveDifficulties(from input: Set<CardDifficulty>) -> Set<CardDifficulty> {
        input.isEmpty ? Set(CardDifficulty.allCases) : input
    }
    
    private func loadStateIfNeeded() -> CatalogState? {
        if let state = cacheQueue.sync(execute: { cachedState }) {
            return state
        }
        
        loadLock.lock()
        defer { loadLock.unlock() }
        
        if let state = cacheQueue.sync(execute: { cachedState }) {
            return state
        }
        
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url, options: .mappedIfSafe)
            let catalog = try JSONDecoder().decode(RawCatalog.self, from: data)
            let prepared = prepareCatalogState(from: catalog)
            cacheQueue.sync {
                cachedState = prepared
                cachedCategories = prepared.categories
                cachedCards.removeAll(keepingCapacity: true)
                cachedCardsOrder.removeAll(keepingCapacity: true)
            }
            return prepared
        } catch {
            return nil
        }
    }
    
    private func prepareCatalogState(from catalog: RawCatalog) -> CatalogState {
        var diagnostics = CatalogDiagnostics()
        var cardsByCategory: [String: [Card]] = [:]
        var allCards: [Card] = []
        let categories = Array(catalog.keys).sorted()
        
        for category in categories {
            guard let entries = catalog[category] else { continue }
            diagnostics.totalEntries += entries.count
            var preparedCards: [Card] = []
            preparedCards.reserveCapacity(entries.count)
            
            for entry in entries {
                let trimmedWord = entry.Kelime.trimmingCharacters(in: .whitespacesAndNewlines)
                let normalizedWord = normalizeToken(trimmedWord)
                guard trimmedWord.isEmpty == false, normalizedWord.isEmpty == false else {
                    diagnostics.rejectedWord += 1
                    continue
                }
                
                guard isValidWord(trimmedWord, normalized: normalizedWord) else {
                    diagnostics.rejectedWord += 1
                    continue
                }
                
                let forbiddenWords = sanitizeForbiddenWords(
                    entry.Yasaklılar,
                    normalizedWord: normalizedWord,
                    category: category
                )
                guard forbiddenWords.count == 5 else {
                    diagnostics.rejectedForbidden += 1
                    continue
                }
                
                let rawDifficulty = entry.Zorluk?.lowercased() ?? ""
                let difficulty = CardDifficulty(rawValue: rawDifficulty) ?? .medium
                if rawDifficulty.isEmpty == false, CardDifficulty(rawValue: rawDifficulty) == nil {
                    diagnostics.unknownDifficulty += 1
                }
                
                let card = Card(word: trimmedWord, forbiddenWords: forbiddenWords, difficulty: difficulty)
                preparedCards.append(card)
                allCards.append(card)
            }
            
            cardsByCategory[category] = preparedCards
        }
        
#if DEBUG
        print(
            "WordProvider warmup: prepared=\(allCards.count)/\(diagnostics.totalEntries), " +
            "rejectedWord=\(diagnostics.rejectedWord), " +
            "rejectedForbidden=\(diagnostics.rejectedForbidden), " +
            "unknownDifficulty=\(diagnostics.unknownDifficulty)"
        )
#endif
        
        return CatalogState(categories: categories, allCards: allCards, cardsByCategory: cardsByCategory)
    }
    
    private func sanitizeForbiddenWords(_ rawWords: [String],
                                        normalizedWord: String,
                                        category: String) -> [String] {
        var seen: Set<String> = []
        var result: [String] = []
        
        func appendCandidate(_ raw: String) {
            guard result.count < 5 else { return }
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            let normalized = normalizeToken(trimmed)
            guard trimmed.isEmpty == false, normalized.isEmpty == false else { return }
            guard normalized != normalizedWord else { return }
            guard isBlockedToken(normalized) == false else { return }
            guard seen.insert(normalized).inserted else { return }
            result.append(trimmed)
        }
        
        for raw in rawWords {
            appendCandidate(raw)
        }
        
        if result.count < 5, let fallbacks = categoryFallbackTokens[category] {
            for fallback in fallbacks {
                appendCandidate(fallback)
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
