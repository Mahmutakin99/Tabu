//
//  TeamGameViewController.swift
//  Tabu
//
//  Created by MAHMUT AKIN on 13/10/2025.
//

import UIKit

final class TeamGameViewController: UIViewController {
    
    private let game: TeamGame
    
    // UI
    private let exitButton = UIButton(type: .system)
    private let timerIconView = UIImageView(image: UIImage(systemName: "timer"))
    private let timerLabel = UILabel()
    private let scoreIconView = UIImageView(image: UIImage(systemName: "star.fill"))
    private let scoreLabel = UILabel()
    private let teamBadgeLabel = UILabel()
    
    // Kart ve dekor
    private let cardView = UIView()
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
    private let wordLabel = UILabel()
    private let chipsWrapView = FlowWrapView()
    private let cardTopSpacer = UIView()      // üst esnek boşluk
    private let cardBottomSpacer = UIView()   // alt esnek boşluk (YENİ)
    
    // Kenarlık ve highlight katmanları
    private let cardBorderLayer = CAGradientLayer()
    private let cardBorderMask = CAShapeLayer()
    private let cardHighlightLayer = CAGradientLayer()
    
    // Arka plan gradient (solo ile aynı)
    private let backgroundGradient = CAGradientLayer()
    
    private let passButton = UIButton(type: .system)
    private let tabooButton = UIButton(type: .system)
    private let correctButton = UIButton(type: .system)
    
    // Haptics
    private let successFeedback = UINotificationFeedbackGenerator()
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let errorFeedback = UINotificationFeedbackGenerator()
    
    // Anim
    private enum CardTransitionDirection { case none, next, previous }
    private enum SwipeDirection { case left, right }
    
    // İlk layout sonrası bir kez daha içerik güncellemek için
    private var didInitialLayout = false
    
    init(settings: TeamGameSettings) {
        self.game = TeamGame(settings: settings)
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Takım modunu açık tema zorunlu yap (karanlıkta da beyaz görünüm için)
        overrideUserInterfaceStyle = .light
        
        view.backgroundColor = .white
        setupBackgroundGradient()
        setupUI()
        setupCardDecorations()
        setupCallbacks()
        updateTeamUI()
        // İlk veri yükleme (ilk layout’tan önce)
        updateCardUI(direction: .none, animated: false)
        // Pas buton başlığını ilk anda senkronize et
        updatePassButton()
        game.startRound()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        backgroundGradient.frame = view.bounds
        layoutCardDecorations()
        cardView.layer.shadowPath = UIBezierPath(roundedRect: cardView.bounds, cornerRadius: 18).cgPath
        CATransaction.commit()
        
        // İlk kez layout oturduktan sonra kart içeriğini bir kez daha güncelle
        if didInitialLayout == false {
            didInitialLayout = true
            // Chips ölçümleri ve gradient maskeleri doğru frame ile hesaplansın
            DispatchQueue.main.async { [weak self] in
                self?.updateCardUI(direction: .none, animated: false)
                self?.updatePassButton()
            }
        }
    }
    
    // MARK: - Background
    private func setupBackgroundGradient() {
        // Açık görünümü korumak için düşük alfa ile yumuşak renkler
        backgroundGradient.colors = [
            UIColor.systemIndigo.withAlphaComponent(0.12).cgColor,
            UIColor.systemTeal.withAlphaComponent(0.12).cgColor,
            UIColor.systemPink.withAlphaComponent(0.14).cgColor
        ]
        backgroundGradient.startPoint = CGPoint(x: 0, y: 0)
        backgroundGradient.endPoint = CGPoint(x: 1, y: 1)
        view.layer.insertSublayer(backgroundGradient, at: 0)
    }
    
    private func setupCallbacks() {
        game.onTimeChanged = { [weak self] left in
            guard let self = self else { return }
            self.timerLabel.text = "Süre: \(left)"
            // Yeni tur başladığında da (left = roundTimeSeconds) pas başlığını tazele
            self.updatePassButton()
        }
        game.onActiveTeamChanged = { [weak self] _ in
            guard let self = self else { return }
            self.updateTeamUI()
            self.updatePassButton()
            self.updateCardUI(direction: .none, animated: true)
        }
        game.onScoreChanged = { [weak self] _ in
            self?.updateScoreLabel()
        }
        game.onRoundEnded = { [weak self] teamIndex, stats, isLast in
            guard let self = self else { return }
            let vc = TeamRoundSummaryViewController(teamName: self.game.teams[teamIndex].name,
                                                    stats: stats,
                                                    isLastRoundOverall: isLast)
            vc.onContinue = { [weak self] in
                self?.dismiss(animated: true, completion: {
                    self?.game.advanceToNextTeamAndStartIfAvailable()
                })
            }
            vc.modalPresentationStyle = .pageSheet
            self.present(vc, animated: true)
        }
        game.onGameOver = { [weak self] teams in
            guard let self = self else { return }
            let message = teams
                .enumerated()
                .map { index, team in
                    "\(index + 1). \(team.name): \(team.score)"
                }
                .joined(separator: "\n")
            let alert = UIAlertController(title: "Oyun Bitti", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Kapat", style: .default, handler: { [weak self] _ in
                self?.dismiss(animated: true, completion: nil)
            }))
            self.present(alert, animated: true)
        }
    }
    
    // MARK: - UI
    private func setupUI() {
        // Çıkış
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
        exitButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        exitButton.setContentHuggingPriority(.required, for: .horizontal)
        exitButton.addTarget(self, action: #selector(exitButtonTapped), for: .touchUpInside)
        exitButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Üst bar
        timerIconView.tintColor = .label
        timerIconView.contentMode = .scaleAspectFit
        timerIconView.setContentHuggingPriority(.required, for: .horizontal)
        timerIconView.setContentCompressionResistancePriority(.required, for: .horizontal)
        timerIconView.translatesAutoresizingMaskIntoConstraints = false
        
        scoreIconView.tintColor = .systemYellow
        scoreIconView.contentMode = .scaleAspectFit
        scoreIconView.setContentHuggingPriority(.required, for: .horizontal)
        scoreIconView.setContentCompressionResistancePriority(.required, for: .horizontal)
        scoreIconView.translatesAutoresizingMaskIntoConstraints = false
        
        timerLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 22, weight: .semibold)
        timerLabel.textAlignment = .left
        
        scoreLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 22, weight: .semibold)
        scoreLabel.textAlignment = .right
        
        let timeStack = UIStackView(arrangedSubviews: [timerIconView, timerLabel])
        timeStack.axis = .horizontal
        timeStack.spacing = 8
        
        let scoreStack = UIStackView(arrangedSubviews: [scoreIconView, scoreLabel])
        scoreStack.axis = .horizontal
        scoreStack.spacing = 8
        
        let topStackView = UIStackView(arrangedSubviews: [timeStack, scoreStack])
        topStackView.axis = .horizontal
        topStackView.distribution = .fillEqually
        topStackView.spacing = 8
        topStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Takım badge’i
        teamBadgeLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        teamBadgeLabel.textColor = .secondaryLabel
        teamBadgeLabel.textAlignment = .center
        teamBadgeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Kart görünümü
        cardView.backgroundColor = UIColor.white
        cardView.layer.cornerRadius = 18
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.22
        cardView.layer.shadowOffset = CGSize(width: 0, height: 6)
        cardView.layer.shadowRadius = 14
        cardView.translatesAutoresizingMaskIntoConstraints = false
        
        // Blur
        blurView.clipsToBounds = true
        blurView.layer.cornerRadius = 18
        blurView.translatesAutoresizingMaskIntoConstraints = false
        
        // İçerik
        wordLabel.font = UIFont.systemFont(ofSize: 36, weight: .heavy)
        wordLabel.textAlignment = .center
        wordLabel.numberOfLines = 0
        wordLabel.translatesAutoresizingMaskIntoConstraints = false
        
        chipsWrapView.translatesAutoresizingMaskIntoConstraints = false
        
        // Spacer’lar
        cardTopSpacer.translatesAutoresizingMaskIntoConstraints = false
        cardBottomSpacer.translatesAutoresizingMaskIntoConstraints = false
        
        // Butonlar
        configureActionButton(passButton, title: "Pas", systemName: "arrow.uturn.left", color: .systemOrange, action: #selector(passTapped))
        configureActionButton(tabooButton, title: "Tabu", systemName: "nosign", color: .systemRed, action: #selector(tabooTapped))
        configureActionButton(correctButton, title: "Doğru", systemName: "checkmark.circle.fill", color: .systemGreen, action: #selector(correctTapped))
        
        let bottomStackView = UIStackView(arrangedSubviews: [passButton, tabooButton, correctButton])
        bottomStackView.axis = .horizontal
        bottomStackView.distribution = .fillEqually
        bottomStackView.spacing = 16
        bottomStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Hiyerarşi
        view.addSubview(exitButton)
        view.addSubview(topStackView)
        view.addSubview(teamBadgeLabel)
        view.addSubview(cardView)
        view.addSubview(bottomStackView)
        
        // Kart içi hiyerarşi
        cardView.addSubview(blurView)
        cardView.addSubview(cardTopSpacer)
        cardView.addSubview(wordLabel)
        cardView.addSubview(cardBottomSpacer)
        cardView.addSubview(chipsWrapView)
        
        NSLayoutConstraint.activate([
            // Çıkış
            exitButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            exitButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            exitButton.heightAnchor.constraint(equalToConstant: 32),
            
            // Üst bar
            topStackView.topAnchor.constraint(equalTo: exitButton.bottomAnchor, constant: 12),
            topStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            topStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            timerIconView.widthAnchor.constraint(equalToConstant: 20),
            timerIconView.heightAnchor.constraint(equalToConstant: 20),
            scoreIconView.widthAnchor.constraint(equalToConstant: 20),
            scoreIconView.heightAnchor.constraint(equalToConstant: 20),
            
            // Badge
            teamBadgeLabel.topAnchor.constraint(equalTo: topStackView.bottomAnchor, constant: 6),
            teamBadgeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            teamBadgeLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Kart
            cardView.topAnchor.constraint(equalTo: teamBadgeLabel.bottomAnchor, constant: 12),
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            cardView.heightAnchor.constraint(greaterThanOrEqualToConstant: 320),
            
            // Blur
            blurView.topAnchor.constraint(equalTo: cardView.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),
            
            // Kart içi – üst spacer
            cardTopSpacer.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 18),
            cardTopSpacer.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            cardTopSpacer.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            
            // Kelime
            wordLabel.topAnchor.constraint(equalTo: cardTopSpacer.bottomAnchor, constant: 8),
            wordLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 14),
            wordLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),
            
            // Alt spacer
            cardBottomSpacer.topAnchor.constraint(equalTo: wordLabel.bottomAnchor, constant: 8),
            cardBottomSpacer.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            cardBottomSpacer.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            cardBottomSpacer.bottomAnchor.constraint(equalTo: chipsWrapView.topAnchor, constant: -18),
            
            // Chips altta sabit
            chipsWrapView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            chipsWrapView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            chipsWrapView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -24),
            
            // Spacer minimumları
            cardTopSpacer.heightAnchor.constraint(greaterThanOrEqualToConstant: 0),
            cardBottomSpacer.heightAnchor.constraint(greaterThanOrEqualToConstant: 0),
            
            // Alt butonlar
            bottomStackView.topAnchor.constraint(equalTo: cardView.bottomAnchor, constant: 30),
            bottomStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            bottomStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            bottomStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            bottomStackView.heightAnchor.constraint(equalToConstant: 80)
        ])
        
        // KELİMEYİ ORTALAYAN KRİTİK KISIT:
        // Üst ve alt spacer yüksekliklerini eşitle.
        let equalSpacers = cardTopSpacer.heightAnchor.constraint(equalTo: cardBottomSpacer.heightAnchor)
        equalSpacers.priority = .required
        equalSpacers.isActive = true
        
        // Hugging/Compression ayarları
        cardTopSpacer.setContentHuggingPriority(.defaultLow, for: .vertical)
        cardBottomSpacer.setContentHuggingPriority(.defaultLow, for: .vertical)
        wordLabel.setContentHuggingPriority(.required, for: .vertical)
        chipsWrapView.setContentHuggingPriority(.required, for: .vertical)
    }
    
    // MARK: - Kart dekor (solo ile birebir)
    private func setupCardDecorations() {
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
    
    private func configureActionButton(_ button: UIButton, title: String, systemName: String, color: UIColor, action: Selector) {
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
        button.layer.shadowColor = UIColor.white.cgColor
        button.layer.shadowOpacity = 0.25
        button.layer.shadowRadius = 8
        button.layer.shadowOffset = CGSize(width: 0, height: 6)
        
        button.addTarget(self, action: #selector(buttonTouchDown(_:)), for: [.touchDown, .touchDragEnter])
        button.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchDragExit, .touchCancel])
        button.addTarget(self, action: action, for: .touchUpInside)
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
    
    // MARK: - UI Updates
    private func updateTeamUI() {
        let team = game.teams[game.activeTeamIndex]
        teamBadgeLabel.text = team.name
        updateScoreLabel()
        updatePassButton()
    }
    
    private func updateScoreLabel() {
        let team = game.teams[game.activeTeamIndex]
        scoreLabel.text = "Skor: \(team.score)"
    }
    
    private func updatePassButton() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.game.settings.isPassUnlimited {
                self.setPassButtonEnabled(true, title: "Pas")
            } else {
                let remaining = self.game.remainingPasses() ?? 0
                let title = "Pas (\(remaining))"
                let enabled = self.game.canPass()
                self.setPassButtonEnabled(enabled, title: title)
            }
        }
    }
    
    private func setPassButtonEnabled(_ enabled: Bool, title: String) {
        if #available(iOS 15.0, *) {
            var config = passButton.configuration ?? .filled()
            config.title = title
            passButton.configuration = config
        } else {
            passButton.setTitle(title, for: .normal)
        }
        passButton.isEnabled = enabled
        passButton.alpha = enabled ? 1.0 : 0.5
    }
    
    private func applyHighlight(color: UIColor) {
        let overlay = UIView(frame: cardView.bounds)
        overlay.backgroundColor = color.withAlphaComponent(0.15)
        overlay.layer.cornerRadius = cardView.layer.cornerRadius
        overlay.isUserInteractionEnabled = false
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        cardView.addSubview(overlay)
        UIView.animate(withDuration: 0.35, delay: 0, options: [.curveEaseOut]) {
            overlay.alpha = 0.0
        } completion: { _ in
            overlay.removeFromSuperview()
        }
        
        let glow = CABasicAnimation(keyPath: "opacity")
        glow.fromValue = 0.0
        glow.toValue = 1.0
        glow.duration = 0.18
        glow.autoreverses = true
        cardHighlightLayer.add(glow, forKey: "glow")
    }
    
    private func shakeCard() {
        let anim = CAKeyframeAnimation(keyPath: "transform.translation.x")
        anim.values = [-8, 8, -6, 6, -3, 3, 0]
        anim.duration = 0.35
        anim.calculationMode = .cubic
        cardView.layer.add(anim, forKey: "shake")
    }
    
    private func updateCardUI(direction: CardTransitionDirection = .none, animated: Bool = true) {
        let update = { [weak self] in
            guard let self = self else { return }
            if let card = self.game.getCurrentCard() {
                self.wordLabel.text = card.word
                self.chipsWrapView.setTags(card.forbiddenWords)
            } else {
                self.wordLabel.text = "-"
                self.chipsWrapView.setTags([])
            }
            // Layout’u zorla ki ilk anda taşma olmasın
            self.cardView.layoutIfNeeded()
            self.view.layoutIfNeeded()
        }
        guard animated else { update(); return }
        UIView.transition(with: cardView, duration: 0.2, options: [.transitionCrossDissolve, .allowAnimatedContent]) {
            update()
        }
    }
    
    // MARK: - Animasyon
    private func animateCard(direction: SwipeDirection, completion: @escaping () -> Void) {
        cardView.layer.removeAllAnimations()
        cardView.transform = .identity
        
        cardView.layer.shouldRasterize = true
        // Use context-derived screen scale (iOS 26+ compatible)
        let scale: CGFloat
        if let screenScale = view.window?.windowScene?.screen.scale {
            scale = screenScale
        } else {
            // Fallback: use traitCollection displayScale or default to 2.0 (Retina)
            scale = view.traitCollection.displayScale > 0 ? view.traitCollection.displayScale : 2.0
        }
        cardView.layer.rasterizationScale = scale
        
        let angle: CGFloat = (direction == .right) ? .pi / 16 : -.pi / 16
        let xOffset: CGFloat = (direction == .right) ? 180 : -180
        let yOffset: CGFloat = -40
        
        let glow = CABasicAnimation(keyPath: "opacity")
        glow.fromValue = 0.0
        glow.toValue = 1.0
        glow.duration = 0.18
        glow.autoreverses = true
        cardHighlightLayer.add(glow, forKey: "glow")
        
        UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseOut]) {
            self.cardView.transform = CGAffineTransform(rotationAngle: angle)
                .translatedBy(x: xOffset, y: yOffset)
        } completion: { _ in
            completion()
            UIView.animate(withDuration: 0.12, delay: 0, options: [.curveEaseIn]) {
                self.cardView.transform = CGAffineTransform(rotationAngle: angle)
                    .translatedBy(x: xOffset * 1.6, y: yOffset - 10)
                    .scaledBy(x: 0.96, y: 0.96)
            } completion: { _ in
                UIView.animate(withDuration: 0.16, delay: 0, options: [.curveEaseOut]) {
                    self.cardView.transform = .identity
                } completion: { _ in
                    self.cardView.layer.shouldRasterize = false
                }
            }
        }
    }
    
    // MARK: - Actions
    @objc private func passTapped() {
        guard game.canPass() else {
            let gen = UINotificationFeedbackGenerator()
            gen.notificationOccurred(.warning)
            return
        }
        impactFeedback.impactOccurred()
        animateCard(direction: .left) { [weak self] in
            guard let self = self else { return }
            self.game.pass()
            self.updateScoreLabel()
            self.updatePassButton()
            self.updateCardUI(direction: .none, animated: false)
        }
    }
    
    @objc private func tabooTapped() {
        impactFeedback.impactOccurred()
        errorFeedback.notificationOccurred(.error)
        shakeCard()
        animateCard(direction: .left) { [weak self] in
            guard let self = self else { return }
            self.game.tabu()
            self.updateScoreLabel()
            self.updatePassButton()
            self.updateCardUI(direction: .none, animated: false)
        }
    }
    
    @objc private func correctTapped() {
        successFeedback.notificationOccurred(.success)
        shakeCard()
        animateCard(direction: .right) { [weak self] in
            guard let self = self else { return }
            self.game.correctAnswer()
            self.updateScoreLabel()
            self.updatePassButton()
            self.updateCardUI(direction: .none, animated: false)
        }
    }
    
    @objc private func exitButtonTapped() {
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
        game.endGame()
        if let presenting = self.presentingViewController {
            presenting.dismiss(animated: true, completion: nil)
            return
        }
        if let nav = self.navigationController {
            nav.popViewController(animated: true)
            return
        }
        self.dismiss(animated: true, completion: nil)
    }
}

