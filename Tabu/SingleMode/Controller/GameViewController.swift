//
//  GameViewController.swift
//  Tabu
//
//  Created by MAHMUT AKIN on 12/10/2025.
//

import UIKit

final class GameViewController: UIViewController {

    private let game: Game
    
    private let timerLabel = UILabel()
    private let scoreLabel = UILabel()
    private let wordLabel = UILabel()
    private let exitButton = UIButton(type: .system)
    
    // Eski forbiddenWordsLabel yerine chip’ler için akış görünümü
    private let chipsWrapView = FlowWrapView()
    
    // Erken çıkışta GameOver açılmasını engellemek için
    private var isEarlyExiting = false
    private var isShowingGameOver = false
    private var wasPausedBySystem = false
    
    // Haptics
    private let successFeedback = UINotificationFeedbackGenerator()
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    // Kart görünümünü animasyonlarda kullanmak için referans
    private let cardView = UIView()
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
    private let cardBorderLayer = CAGradientLayer()
    private let cardBorderMask = CAShapeLayer()
    private let cardHighlightLayer = CAGradientLayer()
    
    // Arka plan gradient
    private let backgroundGradient = CAGradientLayer()
    private var lastDecorLayoutBounds: CGRect = .zero
    private var lastBackgroundBounds: CGRect = .zero
    
    init(cards: [Card], settings: SingleGameSettings = .default()) {
        self.game = Game(cards: cards, settings: settings)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupBackgroundGradient()
        setupUI()
        setupLifecycleObservers()
        setupGameCallbacks()
        prepareFeedbackGenerators()
        startGame()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        game.pauseTimer()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isBeingDismissed || isMovingFromParent {
            game.endGame()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if view.bounds != lastBackgroundBounds {
            lastBackgroundBounds = view.bounds
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            backgroundGradient.frame = view.bounds
            CATransaction.commit()
        }
        
        if cardView.bounds != lastDecorLayoutBounds {
            lastDecorLayoutBounds = cardView.bounds
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            layoutCardDecorations()
            cardView.layer.shadowPath = UIBezierPath(roundedRect: cardView.bounds, cornerRadius: 18).cgPath
            CATransaction.commit()
        }
    }
    
    private func setupBackgroundGradient() {
        backgroundGradient.colors = [
            UIColor.systemIndigo.withAlphaComponent(0.18).cgColor,
            UIColor.systemTeal.withAlphaComponent(0.18).cgColor,
            UIColor.systemPink.withAlphaComponent(0.2).cgColor
        ]
        backgroundGradient.startPoint = CGPoint(x: 0, y: 0)
        backgroundGradient.endPoint = CGPoint(x: 1, y: 1)
        view.layer.insertSublayer(backgroundGradient, at: 0)
    }
    
    private func setupUI() {
        // Zaman ve Skor Etiketleri (ikon + monospaced)
        let timeIcon = makeSymbolLabel(systemName: "timer", tint: .label)
        let scoreIcon = makeSymbolLabel(systemName: "star.fill", tint: .systemYellow)
        
        timerLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 22, weight: .semibold)
        timerLabel.textAlignment = .left
        scoreLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 22, weight: .semibold)
        scoreLabel.textAlignment = .right
        
        let timeStack = UIStackView(arrangedSubviews: [timeIcon, timerLabel])
        timeStack.axis = .horizontal
        timeStack.spacing = 8
        
        let scoreStack = UIStackView(arrangedSubviews: [scoreIcon, scoreLabel])
        scoreStack.axis = .horizontal
        scoreStack.spacing = 8
        
        let topStackView = UIStackView(arrangedSubviews: [timeStack, scoreStack])
        topStackView.distribution = .fillEqually
        topStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Çıkış butonu - kompakt görünüm
        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.plain()
            config.title = "Çıkış"
            config.image = UIImage(systemName: "xmark.circle.fill")
            config.imagePadding = 6
            config.baseForegroundColor = .systemRed
            config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10)
            exitButton.configuration = config
            exitButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        } else {
            exitButton.setTitle("Çıkış", for: .normal)
            exitButton.setTitleColor(.systemRed, for: .normal)
            exitButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
            exitButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
        }
        exitButton.addTarget(self, action: #selector(exitButtonTapped), for: .touchUpInside)
        exitButton.translatesAutoresizingMaskIntoConstraints = false
        exitButton.accessibilityLabel = "Oyundan çık"
        
        // Kart Görünümü + cam efekti ve dekor
        //cardView.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.5)
        cardView.backgroundColor = UIColor.secondarySystemBackground
        cardView.layer.cornerRadius = 18
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.22
        cardView.layer.shadowOffset = CGSize(width: 0, height: 6)
        cardView.layer.shadowRadius = 14
        cardView.translatesAutoresizingMaskIntoConstraints = false
        
        blurView.clipsToBounds = true
        blurView.layer.cornerRadius = 18
        blurView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(blurView)
        
        // Kart baş kelimesi
        wordLabel.font = UIFont.systemFont(ofSize: 36, weight: .heavy)
        wordLabel.textAlignment = .center
        wordLabel.numberOfLines = 0
        wordLabel.translatesAutoresizingMaskIntoConstraints = false
        wordLabel.adjustsFontForContentSizeCategory = true
        
        // Yasaklı kelimeler için chip’ler
        chipsWrapView.translatesAutoresizingMaskIntoConstraints = false
        
        // Butonlar: Pas - Tabu - Doğru
        let passButton = createActionButton(title: "Pas", systemName: "arrow.uturn.left", color: .systemOrange, action: #selector(passButtonTapped))
        let tabooButton = createActionButton(title: "Tabu", systemName: "nosign", color: .systemRed, action: #selector(tabooButtonTapped))
        let correctButton = createActionButton(title: "Doğru", systemName: "checkmark.circle.fill", color: .systemGreen, action: #selector(correctButtonTapped))
        
        let bottomStackView = UIStackView(arrangedSubviews: [passButton, tabooButton, correctButton])
        bottomStackView.distribution = .fillEqually
        bottomStackView.spacing = 16
        bottomStackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(exitButton)
        view.addSubview(topStackView)
        view.addSubview(cardView)
        view.addSubview(bottomStackView)
        
        cardView.addSubview(wordLabel)
        cardView.addSubview(chipsWrapView)
        
        NSLayoutConstraint.activate([
            // Çıkış butonu sol üstte, sabit yükseklik
            exitButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            exitButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            exitButton.heightAnchor.constraint(equalToConstant: 32),
            
            topStackView.topAnchor.constraint(equalTo: exitButton.bottomAnchor, constant: 12),
            topStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            topStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Kart, topStackView’dan sonra başlar ve içeriğine göre aşağı doğru uzar
            cardView.topAnchor.constraint(equalTo: topStackView.bottomAnchor, constant: 20),
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            blurView.topAnchor.constraint(equalTo: cardView.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),
            
            wordLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 26),
            wordLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 14),
            wordLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),
            
            chipsWrapView.topAnchor.constraint(equalTo: wordLabel.bottomAnchor, constant: 18),
            chipsWrapView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            chipsWrapView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            chipsWrapView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -24),
            
            // Alt butonlar kartın altından 30pt sonra gelsin (Team ile aynı)
            bottomStackView.topAnchor.constraint(equalTo: cardView.bottomAnchor, constant: 30),
            bottomStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            bottomStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            bottomStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            bottomStackView.heightAnchor.constraint(equalToConstant: 80)
        ])
        
        // Kart dekor katmanlarını hazırla
        setupCardDecorations()
    }
    
    private func setupCardDecorations() {
        // Gradient border
        cardBorderLayer.colors = [
            UIColor.systemTeal.withAlphaComponent(0.9).cgColor,
            UIColor.systemPurple.withAlphaComponent(0.9).cgColor
        ]
        cardBorderLayer.startPoint = CGPoint(x: 0, y: 0.5)
        cardBorderLayer.endPoint = CGPoint(x: 1, y: 0.5)
        cardBorderLayer.frame = cardView.bounds
        cardView.layer.addSublayer(cardBorderLayer)
        
        cardBorderMask.lineWidth = 2
        cardBorderMask.fillColor = UIColor.clear.cgColor
        cardBorderMask.strokeColor = UIColor.white.withAlphaComponent(0.9).cgColor
        cardBorderLayer.mask = cardBorderMask
        
        // Highlight layer
        cardHighlightLayer.colors = [
            UIColor.white.withAlphaComponent(0.18).cgColor,
            UIColor.clear.cgColor
        ]
        cardHighlightLayer.startPoint = CGPoint(x: 0.2, y: 0)
        cardHighlightLayer.endPoint = CGPoint(x: 0.8, y: 1)
        cardView.layer.insertSublayer(cardHighlightLayer, above: blurView.layer)
    }
    
    private func layoutCardDecorations() {
        let bounds = cardView.bounds
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        cardBorderLayer.frame = bounds
        cardHighlightLayer.frame = bounds
        let path = UIBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), cornerRadius: 18)
        cardBorderMask.path = path.cgPath
        CATransaction.commit()
    }
    
    private func makeSymbolLabel(systemName: String, tint: UIColor) -> UIImageView {
        let iv = UIImageView(image: UIImage(systemName: systemName))
        iv.tintColor = tint
        iv.contentMode = .scaleAspectFit
        iv.setContentHuggingPriority(.required, for: .horizontal)
        iv.setContentCompressionResistancePriority(.required, for: .horizontal)
        return iv
    }
    
    private func createActionButton(title: String, systemName: String, color: UIColor, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        
        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.filled()
            config.title = title
            config.image = UIImage(systemName: systemName)
            config.imagePadding = 8
            config.baseBackgroundColor = color
            config.baseForegroundColor = .white
            config.cornerStyle = .large
            config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
            button.configuration = config
            button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 22)
        } else {
            button.setTitle(title, for: .normal)
            button.setImage(UIImage(systemName: systemName), for: .normal)
            button.tintColor = .white
            button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 22)
            button.backgroundColor = color
            button.setTitleColor(.white, for: .normal)
            button.layer.cornerRadius = 15
            button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
            button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -6, bottom: 0, right: 6)
        }
        
        // Gölge ve basma animasyonu
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.25
        button.layer.shadowRadius = 8
        button.layer.shadowOffset = CGSize(width: 0, height: 6)
        
        button.addTarget(self, action: #selector(buttonTouchDown(_:)), for: [.touchDown, .touchDragEnter])
        button.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchDragExit, .touchCancel])
        button.addTarget(self, action: action, for: .touchUpInside)
        button.accessibilityLabel = title
        return button
    }
    
    @objc private func buttonTouchDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.08) {
            sender.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
            sender.layer.shadowRadius = 4
            sender.layer.shadowOffset = CGSize(width: 0, height: 3)
            sender.layer.shadowOpacity = 0.18
        }
    }
    
    @objc private func buttonTouchUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.12) {
            sender.transform = .identity
            sender.layer.shadowRadius = 8
            sender.layer.shadowOffset = CGSize(width: 0, height: 6)
            sender.layer.shadowOpacity = 0.25
        }
    }
    
    private func setupGameCallbacks() {
        game.onTimeChanged = { [weak self] timeLeft in
            self?.timerLabel.text = "Süre: \(timeLeft)"
            self?.timerLabel.accessibilityValue = "\(timeLeft)"
        }
        
        game.onGameOver = { [weak self] finalScore in
            // Erken çıkış durumunda GameOver açma
            guard let self = self, self.isEarlyExiting == false else { return }
            self.showGameOverScreen(score: finalScore)
        }
    }
    
    private func setupLifecycleObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    private func prepareFeedbackGenerators() {
        successFeedback.prepare()
        impactFeedback.prepare()
    }
    
    private func startGame() {
        isEarlyExiting = false
        game.startGame()
        updateUI()
    }
    
    private func updateUI() {
        scoreLabel.text = "Skor: \(game.score)"
        if let currentCard = game.getCurrentCard() {
            wordLabel.text = currentCard.word
            chipsWrapView.setTags(currentCard.forbiddenWords)
        } else {
            wordLabel.text = "-"
            chipsWrapView.setTags([])
        }
    }
    
    @objc private func passButtonTapped() {
        impactFeedback.impactOccurred()
        animateCard(direction: .left) { [weak self] in
            self?.game.pass()
            self?.updateUI()
            self?.prepareFeedbackGenerators()
        }
    }
    
    @objc private func tabooButtonTapped() {
        impactFeedback.impactOccurred()
        animateCard(direction: .left) { [weak self] in
            self?.game.tabu()
            self?.updateUI()
            self?.prepareFeedbackGenerators()
        }
    }
    
    @objc private func correctButtonTapped() {
        successFeedback.notificationOccurred(.success)
        animateCard(direction: .right) { [weak self] in
            self?.game.correctAnswer()
            self?.updateUI()
            self?.prepareFeedbackGenerators()
        }
    }
    
    // Yelpaze animasyonu + highlight (Team moddaki zamanlama/eğrilerle uyumlu)
    private enum SwipeDirection { case left, right }
    // MARK: - Animasyon
    private func animateCard(direction: SwipeDirection, completion: @escaping () -> Void) {
        // Başlangıç transform’u sıfırla
        cardView.layer.removeAllAnimations()
        cardView.transform = .identity
        
        // Rasterize during animation for smoother performance
        cardView.layer.shouldRasterize = true
        // Use context-derived screen scale.
        let scale: CGFloat
        if let screenScale = view.window?.windowScene?.screen.scale {
            scale = screenScale
        } else {
            // Fallback: use traitCollection displayScale or default to 2.0 (Retina)
            scale = view.traitCollection.displayScale > 0 ? view.traitCollection.displayScale : 2.0
        }
        cardView.layer.rasterizationScale = scale
        
        // Hareket parametreleri (Team ile aynı)
        let angle: CGFloat = (direction == .right) ? .pi / 16 : -.pi / 16 // ~11.25°
        let xOffset: CGFloat = (direction == .right) ? 180 : -180
        let yOffset: CGFloat = -40
        
        // Highlight parıltısı (Team ile aynı)
        let glow = CABasicAnimation(keyPath: "opacity")
        glow.fromValue = 0.0
        glow.toValue = 1.0
        glow.duration = 0.18
        glow.autoreverses = true
        cardHighlightLayer.add(glow, forKey: "glow")
        
        // 1. faz
        UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseOut]) {
            self.cardView.transform = CGAffineTransform(rotationAngle: angle)
                .translatedBy(x: xOffset, y: yOffset)
        } completion: { _ in
            // İçeriği değiştir
            completion()
            // 2. faz (hızlanma + scale)
            UIView.animate(withDuration: 0.12, delay: 0, options: [.curveEaseIn]) {
                self.cardView.transform = CGAffineTransform(rotationAngle: angle)
                    .translatedBy(x: xOffset * 1.6, y: yOffset - 10)
                    .scaledBy(x: 0.96, y: 0.96)
            } completion: { _ in
                // Geri dön
                UIView.animate(withDuration: 0.16, delay: 0, options: [.curveEaseOut]) {
                    self.cardView.transform = .identity
                } completion: { _ in
                    self.cardView.layer.shouldRasterize = false
                }
            }
        }
    }
    
    // Erken çıkış akışı
    @objc private func exitButtonTapped() {
        guard presentedViewController == nil else { return }
        let alert = UIAlertController(title: "Oyunu Bitir?",
                                      message: "Süre dolmadan çıkmak istiyor musunuz?",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "İptal", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Evet", style: .destructive, handler: { [weak self] _ in
            self?.earlyFinish()
        }))
        present(alert, animated: true)
    }
    
    private func earlyFinish() {
        // Erken çıkış bayrağı
        isEarlyExiting = true
        // Oyunu durdur (timer invalidate)
        game.endGame()
        
        // Modally sunulduysa tüm modalları kapat
        if let presenting = self.presentingViewController {
            presenting.dismiss(animated: true, completion: nil)
            return
        }
        
        // Navigation içindeyse geri dön
        if let nav = self.navigationController {
            nav.popViewController(animated: true)
            return
        }
        
        // Fallback: kendini kapatmayı dene
        self.dismiss(animated: true, completion: nil)
    }
    
    private func showGameOverScreen(score: Int) {
        guard isShowingGameOver == false else { return }
        guard view.window != nil else { return }
        if let presented = presentedViewController {
            presented.dismiss(animated: false) { [weak self] in
                self?.showGameOverScreen(score: score)
            }
            return
        }
        
        isShowingGameOver = true
        let gameOverVC = GameOverViewController()
        gameOverVC.finalScore = score
        gameOverVC.onPlayAgain = { [weak self] in
            self?.isShowingGameOver = false
            self?.dismiss(animated: false, completion: {
                self?.startGame()
            })
        }
        gameOverVC.modalPresentationStyle = .fullScreen
        present(gameOverVC, animated: true)
    }
    
    @objc private func handleWillResignActive() {
        guard isEarlyExiting == false else { return }
        guard game.isGameActive else { return }
        guard presentedViewController == nil else { return }
        
        wasPausedBySystem = true
        game.pauseTimer()
    }
    
    @objc private func handleDidBecomeActive() {
        guard wasPausedBySystem else { return }
        guard isEarlyExiting == false else { return }
        guard view.window != nil else { return }
        guard presentedViewController == nil else { return }
        
        wasPausedBySystem = false
        game.resumeTimerIfNeeded()
    }
}
