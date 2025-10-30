//
//  Game.swift
//  Tabu
//
//  Created by MAHMUT AKIN on 13/10/2025.
//

import Foundation

class Game {
    
    // Oyun Durumu
    private(set) var score = 0
    private(set) var timeLeft = 60
    private var timer: Timer?
    
    // Kart Yönetimi
    private var cards: [Card]
    private var currentCardIndex = 0
    
    // Ayarlar
    var passPenaltyEnabled: Bool = false
    var passPenaltyValue: Int = 1
    var loopThroughDeck: Bool = true
    
    // Tabu ayarı
    var tabuPenaltyValue: Int = 1
    
    // Callback’ler
    var onTimeChanged: ((Int) -> Void)?
    var onGameOver: ((Int) -> Void)?
    
    init() {
        // Önce kullanıcı seçimlerine göre kartları dene
        let selectedCards = SettingsManager.shared.sharedProvideCardsSafe()
        if selectedCards.isEmpty == false {
            self.cards = selectedCards
        } else if let loaded = Game.loadCardsFromJSON() {
            self.cards = loaded
        } else {
            self.cards = Game.createSampleCards()
        }
        shuffleCards()
    }
    
    func startGame() {
        timer?.invalidate()
        timer = nil
        
        score = 0
        timeLeft = 60
        shuffleCards()
        currentCardIndex = 0
        onTimeChanged?(timeLeft)
        
        let timer = Timer.scheduledTimer(timeInterval: 1.0,
                                         target: self,
                                         selector: #selector(updateTimer),
                                         userInfo: nil,
                                         repeats: true)
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }
    
    @objc private func updateTimer() {
        if timeLeft > 0 {
            timeLeft -= 1
            onTimeChanged?(timeLeft)
        } else {
            endGame()
        }
    }
    
    func endGame() {
        timer?.invalidate()
        timer = nil
        onGameOver?(score)
    }
    
    func getCurrentCard() -> Card? {
        guard !cards.isEmpty else {
            endGame()
            return nil
        }
        guard currentCardIndex < cards.count else {
            handleDeckEnd()
            return currentCardIndex < cards.count ? cards[currentCardIndex] : nil
        }
        return cards[currentCardIndex]
    }
    
    private func handleDeckEnd() {
        if loopThroughDeck {
            shuffleCards()
            currentCardIndex = 0
        } else {
            endGame()
        }
    }
    
    func nextCard() {
        if currentCardIndex < cards.count - 1 {
            currentCardIndex += 1
        } else {
            handleDeckEnd()
        }
    }
    
    func correctAnswer() {
        score += 1
        nextCard()
    }
    
    func pass() {
        if passPenaltyEnabled {
            score = max(0, score - passPenaltyValue)
        }
        nextCard()
    }
    
    func tabu() {
        score -= tabuPenaltyValue
        nextCard()
    }
    
    private func shuffleCards() {
        cards.shuffle()
    }
    
    // MARK: - JSON Yükleme
    private static func loadCardsFromJSON() -> [Card]? {
        let fileName = "tabu_astronomi_fizik_mühendislik"
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let cards = try decoder.decode([Card].self, from: data)
            return cards
        } catch {
            return nil
        }
    }
    
    private static func createSampleCards() -> [Card] {
        return [
            Card(word: "ELMA", forbiddenWords: ["Meyve", "Kırmızı", "Ağaç", "Telefon", "Newton"]),
            Card(word: "GİTAR", forbiddenWords: ["Müzik", "Tel", "Pena", "Enstrüman", "Rock"]),
            Card(word: "KAHVE", forbiddenWords: ["İçecek", "Fincan", "Sıcak", "Kafein", "Süt"]),
            Card(word: "KÖPEK", forbiddenWords: ["Hayvan", "Havlamak", "Sadık", "Evcil", "Kedi"])
        ]
    }
}

// Küçük yardımcı: SettingsManager üzerinden güvenli kart alma
private extension SettingsManager {
    func sharedProvideCardsSafe() -> [Card] {
        let cards = provideCards()
        return cards
    }
}

