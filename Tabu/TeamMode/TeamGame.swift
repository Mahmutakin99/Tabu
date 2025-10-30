//
//  TeamGame.swift
//  Tabu
//
//  Created by MAHMUT AKIN on 13/10/2025.
//

import Foundation

struct RoundStats {
    var correct: Int = 0
    var tabu: Int = 0
    var pass: Int = 0
}

final class TeamGame {
    
    private(set) var settings: TeamGameSettings
    private(set) var teams: [Team]
    private(set) var activeTeamIndex: Int = 0
    
    private(set) var timeLeft: Int
    private var timer: Timer?
    
    private(set) var currentPassCount: Int = 0
    
    private var cards: [Card] = []
    private var currentCardIndex: Int = 0
    var loopThroughDeck: Bool = true
    
    private var roundsPlayedPerTeam: [Int]
    private(set) var currentRoundStats = RoundStats()
    
    var onTimeChanged: ((Int) -> Void)?
    var onActiveTeamChanged: ((Team) -> Void)?
    var onScoreChanged: (([Team]) -> Void)?
    var onGameOver: (([Team]) -> Void)?
    var onRoundEnded: ((Int, RoundStats, Bool) -> Void)?
    
    init(settings: TeamGameSettings) {
        self.settings = settings
        self.teams = settings.teamNames.prefix(settings.teamCount).map { Team(name: $0, score: 0) }
        self.timeLeft = settings.roundTimeSeconds
        self.roundsPlayedPerTeam = Array(repeating: 0, count: teams.count)
        loadCards()
        shuffleCards()
    }
    
    func startRound() {
        timer?.invalidate()
        timeLeft = settings.roundTimeSeconds
        currentPassCount = 0
        currentRoundStats = RoundStats()
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
            endRound(showSummary: true)
        }
    }
    
    func endRound(showSummary: Bool) {
        timer?.invalidate()
        timer = nil
        
        roundsPlayedPerTeam[activeTeamIndex] += 1
        
        let totalRequired = settings.roundsPerTeam
        let allDone = roundsPlayedPerTeam.allSatisfy { $0 >= totalRequired }
        
        if showSummary {
            onRoundEnded?(activeTeamIndex, currentRoundStats, allDone)
        } else if allDone {
            endGame()
        }
    }
    
    func advanceToNextTeamAndStartIfAvailable() {
        let totalRequired = settings.roundsPerTeam
        let allDone = roundsPlayedPerTeam.allSatisfy { $0 >= totalRequired }
        if allDone {
            endGame()
            return
        }
        
        var nextIndex = (activeTeamIndex + 1) % teams.count
        var attempts = 0
        while roundsPlayedPerTeam[nextIndex] >= totalRequired && attempts < teams.count {
            nextIndex = (nextIndex + 1) % teams.count
            attempts += 1
        }
        activeTeamIndex = nextIndex
        onActiveTeamChanged?(teams[activeTeamIndex])
        startRound()
    }
    
    func endGame() {
        timer?.invalidate()
        timer = nil
        onGameOver?(teams)
    }
    
    func getCurrentCard() -> Card? {
        guard !cards.isEmpty else { return nil }
        guard currentCardIndex < cards.count else {
            handleDeckEnd()
            return currentCardIndex < cards.count ? cards[currentCardIndex] : nil
        }
        return cards[currentCardIndex]
    }
    func nextCard() {
        if currentCardIndex < cards.count - 1 {
            currentCardIndex += 1
        } else {
            handleDeckEnd()
        }
    }
    private func handleDeckEnd() {
        if loopThroughDeck {
            shuffleCards()
            currentCardIndex = 0
        } else {
            endGame()
        }
    }
    
    func correctAnswer() {
        teams[activeTeamIndex].score += 1
        currentRoundStats.correct += 1
        onScoreChanged?(teams)
        nextCard()
    }
    func tabu(penalty: Int = 1) {
        teams[activeTeamIndex].score -= penalty
        currentRoundStats.tabu += 1
        onScoreChanged?(teams)
        nextCard()
    }
    func canPass() -> Bool {
        if settings.isPassUnlimited { return true }
        return currentPassCount < settings.passLimit
    }
    func remainingPasses() -> Int? {
        if settings.isPassUnlimited { return nil }
        return max(0, settings.passLimit - currentPassCount)
    }
    func pass() {
        guard canPass() else { return }
        currentPassCount += 1
        currentRoundStats.pass += 1
        nextCard()
    }
}

// MARK: - Private Helpers
private extension TeamGame {
    func loadCards() {
        // Önce kullanıcı seçimlerine göre kart al
        let selectedCards = SettingsManager.shared.sharedProvideCardsSafe()
        if selectedCards.isEmpty == false {
            self.cards = selectedCards
            return
        }
        // Fallback: eski JSON veya örnekler
        let fileName = "tabu_astronomi_fizik_mühendislik"
        if let url = Bundle.main.url(forResource: fileName, withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([Card].self, from: data),
           decoded.isEmpty == false {
            self.cards = decoded
        } else {
            self.cards = [
                Card(word: "ELMA", forbiddenWords: ["Meyve", "Kırmızı", "Ağaç", "Telefon", "Newton"]),
                Card(word: "GİTAR", forbiddenWords: ["Müzik", "Tel", "Pena", "Enstrüman", "Rock"]),
                Card(word: "KAHVE", forbiddenWords: ["İçecek", "Fincan", "Sıcak", "Kafein", "Süt"]),
                Card(word: "KÖPEK", forbiddenWords: ["Hayvan", "Havlamak", "Sadık", "Evcil", "Kedi"])
            ]
        }
    }
    func shuffleCards() {
        cards.shuffle()
    }
}

// Küçük yardımcı: SettingsManager üzerinden güvenli kart alma
private extension SettingsManager {
    func sharedProvideCardsSafe() -> [Card] {
        let cards = provideCards()
        return cards
    }
}

