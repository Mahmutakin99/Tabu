//
//  Card.swift
//  Tabu
//
//  Created by MAHMUT AKIN on 13/10/2025.
//

import Foundation

enum CardDifficulty: String, Codable, CaseIterable {
    case easy
    case medium
    case hard
    
    var title: String {
        switch self {
        case .easy: return "Kolay"
        case .medium: return "Orta"
        case .hard: return "Zor"
        }
    }
}

struct Card: Codable {
    let word: String
    let forbiddenWords: [String]
    let difficulty: CardDifficulty
    
    init(word: String, forbiddenWords: [String], difficulty: CardDifficulty = .medium) {
        self.word = word
        self.forbiddenWords = forbiddenWords
        self.difficulty = difficulty
    }
    
    private enum CodingKeys: String, CodingKey {
        case word
        case forbiddenWords
        case difficulty
        case Kelime
        case Yasaklılar
        case Zorluk
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.word = try container.decodeIfPresent(String.self, forKey: .word)
            ?? container.decode(String.self, forKey: .Kelime)
        self.forbiddenWords = try container.decodeIfPresent([String].self, forKey: .forbiddenWords)
            ?? container.decode([String].self, forKey: .Yasaklılar)
        
        let rawDifficulty = try container.decodeIfPresent(String.self, forKey: .difficulty)
            ?? container.decodeIfPresent(String.self, forKey: .Zorluk)
        self.difficulty = CardDifficulty(rawValue: rawDifficulty?.lowercased() ?? "") ?? .medium
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(word, forKey: .word)
        try container.encode(forbiddenWords, forKey: .forbiddenWords)
        try container.encode(difficulty.rawValue, forKey: .difficulty)
    }
}
