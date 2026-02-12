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
    private(set) var isRoundActive: Bool = false
    private var timer: Timer?
    
    private(set) var currentPassCount: Int = 0
    private(set) var isGameOver: Bool = false
    
    private var cards: [Card] = []
    private var deckIndices: [Int] = []
    private var currentDeckIndex: Int = 0
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
        rebuildDeck()
    }
    
    func startRound() {
        guard isGameOver == false else { return }
        stopTimer()
        isRoundActive = true
        timeLeft = settings.roundTimeSeconds
        currentPassCount = 0
        currentRoundStats = RoundStats()
        
        // Yeni turun başında bir kartın hazır olduğundan emin ol
        ensureCardReady()
        
        onTimeChanged?(timeLeft)
        
        startTimerIfNeeded()
    }
    
    @objc private func updateTimer() {
        guard isRoundActive else { return }
        guard timeLeft > 0 else {
            // Süre bitti: ekranda kalan aktif kartın yeni tura sarkmaması için ilerlet
            discardActiveCardAtRoundEndIfAny()
            endRound(showSummary: true)
            return
        }
        
        timeLeft -= 1
        onTimeChanged?(timeLeft)
        
        if timeLeft == 0 {
            // Süre bitti: ekranda kalan aktif kartın yeni tura sarkmaması için ilerlet
            discardActiveCardAtRoundEndIfAny()
            endRound(showSummary: true)
        }
    }
    
    func endRound(showSummary: Bool) {
        guard isRoundActive else {
            stopTimer()
            return
        }
        
        stopTimer()
        isRoundActive = false
        
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
        guard isGameOver == false else { return }
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
        guard isGameOver == false else { return }
        isGameOver = true
        stopTimer()
        isRoundActive = false
        onGameOver?(teams)
    }
    
    func pauseRoundTimer() {
        stopTimer()
    }
    
    func resumeRoundTimerIfNeeded() {
        guard isRoundActive, timeLeft > 0 else { return }
        startTimerIfNeeded()
    }
    
    func getCurrentCard() -> Card? {
        guard !cards.isEmpty else { return nil }
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
    func nextCard() {
        if currentDeckIndex < deckIndices.count - 1 {
            currentDeckIndex += 1
        } else {
            handleDeckEnd()
        }
    }
    private func handleDeckEnd() {
        if loopThroughDeck {
            rebuildDeck()
            currentDeckIndex = 0
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
        let selectedCards = SettingsManager.shared.provideCards()
        if selectedCards.isEmpty == false {
            self.cards = selectedCards
            return
        }
        
        self.cards = [
            Card(word: "ELMA", forbiddenWords: ["Meyve", "Kırmızı", "Ağaç", "Telefon", "Newton"], difficulty: .easy),
            Card(word: "GİTAR", forbiddenWords: ["Müzik", "Tel", "Pena", "Enstrüman", "Rock"], difficulty: .easy),
            Card(word: "KAHVE", forbiddenWords: ["İçecek", "Fincan", "Sıcak", "Kafein", "Süt"], difficulty: .medium),
            Card(word: "KÖPEK", forbiddenWords: ["Hayvan", "Havlamak", "Sadık", "Evcil", "Kedi"], difficulty: .easy)
        ]
    }
    
    func rebuildDeck() {
        deckIndices = Array(cards.indices)
        deckIndices.shuffle()
    }
    
    // Yeni tur başlarken kartın hazır olmasını garanti eder
    func ensureCardReady() {
        _ = getCurrentCard()
    }
    
    // Süre bittiğinde ekranda kalan aktif kartın bir sonraki tura taşınmaması için ilerlet
    func discardActiveCardAtRoundEndIfAny() {
        guard !cards.isEmpty else { return }
        // getCurrentCard ile gerekirse deste sonu akışı tetiklenir
        if getCurrentCard() != nil {
            nextCard()
        }
    }
    
    func startTimerIfNeeded() {
        guard timer == nil, isRoundActive else { return }
        
        let timer = Timer(timeInterval: 1.0,
                          target: self,
                          selector: #selector(updateTimer),
                          userInfo: nil,
                          repeats: true)
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
