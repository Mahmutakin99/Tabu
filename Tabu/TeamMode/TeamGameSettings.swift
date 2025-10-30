//
//  TeamGameSettings.swift
//  Tabu
//
//  Created by MAHMUT AKIN on 13/10/2025.
//

import Foundation

struct TeamGameSettings: Equatable, Codable {
    var teamCount: Int
    var teamNames: [String]
    var roundTimeSeconds: Int
    var isPassUnlimited: Bool
    var passLimit: Int // sadece isPassUnlimited == false ise kullanılır
    var roundsPerTeam: Int // her takımın oynayacağı tur sayısı

    static func `default`() -> TeamGameSettings {
        let count = 2
        return TeamGameSettings(
            teamCount: count,
            teamNames: (0..<count).map { "Takım \($0 + 1)" },
            roundTimeSeconds: 60,
            isPassUnlimited: false,
            passLimit: 3,
            roundsPerTeam: 2
        )
    }
}

