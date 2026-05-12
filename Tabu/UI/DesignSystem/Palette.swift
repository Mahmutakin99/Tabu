import UIKit

enum Palette {
    // Background gradient stops (game stage)
    static let gameGradientColors: [UIColor] = [
        UIColor.systemIndigo.withAlphaComponent(0.16),
        UIColor.systemTeal.withAlphaComponent(0.16),
        UIColor.systemPink.withAlphaComponent(0.18)
    ]

    // GameOver gradient stops
    static let gameOverGradientColors: [UIColor] = [
        UIColor.systemRed.withAlphaComponent(0.22),
        UIColor.systemOrange.withAlphaComponent(0.18),
        UIColor.systemPink.withAlphaComponent(0.20)
    ]

    // MainMenu gradient stops
    static let menuGradientColors: [UIColor] = [
        UIColor.systemIndigo,
        UIColor(red: 0.12, green: 0.45, blue: 0.78, alpha: 1),
        UIColor.systemTeal.withAlphaComponent(0.85)
    ]

    // Team color presets (6 distinct)
    static let teamColors: [UIColor] = [
        UIColor.systemBlue,
        UIColor.systemPink,
        UIColor.systemGreen,
        UIColor.systemOrange,
        UIColor.systemPurple,
        UIColor.systemRed
    ]

    // Card border gradient (teal → purple)
    static let cardBorderColors: [UIColor] = [
        UIColor.systemTeal,
        UIColor.systemPurple
    ]
}
