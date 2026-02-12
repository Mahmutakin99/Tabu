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
    private(set) var isGameActive = false
    private var timer: Timer?
    
    // Kart Yönetimi
    private var cards: [Card]
    private var deckIndices: [Int] = []
    private var currentDeckIndex = 0
    
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
        let selectedCards = SettingsManager.shared.provideCards()
        if selectedCards.isEmpty == false {
            self.cards = selectedCards
        } else {
            self.cards = Game.createSampleCards()
        }
        rebuildDeck()
    }
    
    func startGame() {
        stopTimer()
        
        score = 0
        timeLeft = 60
        isGameActive = true
        rebuildDeck()
        currentDeckIndex = 0
        onTimeChanged?(timeLeft)
        startTimerIfNeeded()
    }
    
    @objc private func updateTimer() {
        guard isGameActive else { return }
        guard timeLeft > 0 else {
            endGame()
            return
        }
        
        timeLeft -= 1
        onTimeChanged?(timeLeft)
        
        if timeLeft == 0 {
            endGame()
        }
    }
    
    func endGame() {
        guard isGameActive else {
            stopTimer()
            return
        }
        isGameActive = false
        stopTimer()
        onGameOver?(score)
    }
    
    func pauseTimer() {
        stopTimer()
    }
    
    func resumeTimerIfNeeded() {
        guard isGameActive, timeLeft > 0 else { return }
        startTimerIfNeeded()
    }
    
    func getCurrentCard() -> Card? {
        guard !cards.isEmpty else {
            endGame()
            return nil
        }
        guard currentDeckIndex < deckIndices.count else {
            handleDeckEnd()
            return currentDeckIndex < deckIndices.count ? cards[deckIndices[currentDeckIndex]] : nil
        }
        let cardIndex = deckIndices[currentDeckIndex]
        guard cards.indices.contains(cardIndex) else {
            handleDeckEnd()
            return currentDeckIndex < deckIndices.count ? cards[deckIndices[currentDeckIndex]] : nil
        }
        return cards[cardIndex]
    }
    
    private func handleDeckEnd() {
        if loopThroughDeck {
            rebuildDeck()
            currentDeckIndex = 0
        } else {
            endGame()
        }
    }
    
    func nextCard() {
        if currentDeckIndex < deckIndices.count - 1 {
            currentDeckIndex += 1
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
    
    private func rebuildDeck() {
        deckIndices = Array(cards.indices)
        deckIndices.shuffle()
    }
    
    private func startTimerIfNeeded() {
        guard timer == nil, isGameActive else { return }
        let timer = Timer(timeInterval: 1.0,
                          target: self,
                          selector: #selector(updateTimer),
                          userInfo: nil,
                          repeats: true)
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
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
