//
//  Card.swift
//  Tabu
//
//  Created by MAHMUT AKIN on 13/10/2025.
//

import Foundation

struct Card: Codable {
    let word: String
    let forbiddenWords: [String]
}
