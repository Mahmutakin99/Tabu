//
//  Team.swift
//  Tabu
//
//  Created by MAHMUT AKIN on 13/10/2025.
//

import Foundation
import UIKit

struct Team: Equatable, Hashable {
    var name: String
    var score: Int = 0
    var color: UIColor = .systemBlue

    static func == (lhs: Team, rhs: Team) -> Bool {
        lhs.name == rhs.name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

