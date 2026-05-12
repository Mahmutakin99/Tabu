//
//  GameOverViewController.swift
//  Tabu
//
//  Created by MAHMUT AKIN on 13/10/2025.
//

import UIKit

final class GameOverViewController: UIViewController {

    var finalScore: Int = 0
    var isTimerExpired: Bool = true   // false → deck tükendi
    var onPlayAgain: (() -> Void)?
    var onExitToMenu: (() -> Void)?

    private let backgroundView = GradientBackgroundView(colors: Palette.gameOverGradientColors)
    private let gameOverLabel = UILabel()
    private let scoreLabel = UILabel()
    private let contentCard = UIView()

    private var displayLink: CADisplayLink?
    private var countUpStart: CFTimeInterval = 0
    private var countUpDuration: CFTimeInterval = 0.7

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupBackground()
        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        playEntrance()
    }

    private func setupBackground() {
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(backgroundView, at: 0)
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupUI() {
        gameOverLabel.text = isTimerExpired ? "Süre Doldu!" : "Kartlar Bitti!"
        gameOverLabel.font = UIFontMetrics(forTextStyle: .largeTitle)
            .scaledFont(for: UIFont.boldSystemFont(ofSize: 42))
        gameOverLabel.adjustsFontForContentSizeCategory = true
        gameOverLabel.textColor = .label
        gameOverLabel.textAlignment = .center

        scoreLabel.text = "Skorunuz: 0"
        scoreLabel.font = UIFontMetrics(forTextStyle: .title1)
            .scaledFont(for: UIFont.systemFont(ofSize: 30, weight: .semibold))
        scoreLabel.adjustsFontForContentSizeCategory = true
        scoreLabel.textColor = .secondaryLabel
        scoreLabel.textAlignment = .center

        let playAgainButton = AnimatedActionButton(title: "Tekrar Oyna",
                                                   systemName: "arrow.clockwise",
                                                   color: .systemIndigo)
        playAgainButton.addTarget(self, action: #selector(playAgainTapped), for: .touchUpInside)
        playAgainButton.accessibilityLabel = "Tekrar oyna"

        let exitButton = AnimatedActionButton(title: "Ana Menüye Dön",
                                              systemName: "house.fill",
                                              color: .systemGray)
        exitButton.addTarget(self, action: #selector(exitToMenuTapped), for: .touchUpInside)
        exitButton.accessibilityLabel = "Ana menüye dön"

        let labelStack = UIStackView(arrangedSubviews: [gameOverLabel, scoreLabel])
        labelStack.axis = .vertical
        labelStack.spacing = Spacing.m
        labelStack.alignment = .center

        let buttonStack = UIStackView(arrangedSubviews: [playAgainButton, exitButton])
        buttonStack.axis = .vertical
        buttonStack.spacing = Spacing.l
        buttonStack.alignment = .fill

        let mainStack = UIStackView(arrangedSubviews: [labelStack, buttonStack])
        mainStack.axis = .vertical
        mainStack.spacing = Spacing.xxl
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        contentCard.translatesAutoresizingMaskIntoConstraints = false
        contentCard.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.72)
        contentCard.layer.cornerRadius = Radius.card
        Shadow.card.apply(to: contentCard.layer)
        contentCard.addSubview(mainStack)

        view.addSubview(contentCard)

        let inset = Spacing.xl
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: contentCard.topAnchor, constant: inset),
            mainStack.leadingAnchor.constraint(equalTo: contentCard.leadingAnchor, constant: inset),
            mainStack.trailingAnchor.constraint(equalTo: contentCard.trailingAnchor, constant: -inset),
            mainStack.bottomAnchor.constraint(equalTo: contentCard.bottomAnchor, constant: -inset),

            contentCard.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            contentCard.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            contentCard.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: Spacing.xxl),
            contentCard.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -Spacing.xxl),

            playAgainButton.heightAnchor.constraint(equalToConstant: 56),
            exitButton.heightAnchor.constraint(equalToConstant: 56),
            buttonStack.widthAnchor.constraint(equalToConstant: 240)
        ])
    }

    private func playEntrance() {
        contentCard.alpha = 0
        contentCard.transform = CGAffineTransform(scaleX: 0.82, y: 0.82)

        UIView.animate(withDuration: 0.45, delay: 0.05,
                       usingSpringWithDamping: 0.65, initialSpringVelocity: 0.6) {
            self.contentCard.alpha = 1
            self.contentCard.transform = .identity
        } completion: { _ in
            self.startCountUp()
        }

        if finalScore >= 3 {
            Haptics.shared.success()
        } else {
            Haptics.shared.warning()
        }
    }

    private func startCountUp() {
        guard finalScore > 0 else {
            scoreLabel.text = "Skorunuz: 0"
            return
        }
        countUpStart = CACurrentMediaTime()
        let link = CADisplayLink(target: self, selector: #selector(countUpTick))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    @objc private func countUpTick() {
        let elapsed = CACurrentMediaTime() - countUpStart
        let progress = min(elapsed / countUpDuration, 1.0)
        let eased = 1 - pow(1 - progress, 3)
        let current = Int(Double(finalScore) * eased)
        scoreLabel.text = "Skorunuz: \(current)"
        if progress >= 1.0 {
            scoreLabel.text = "Skorunuz: \(finalScore)"
            displayLink?.invalidate()
            displayLink = nil
        }
    }

    @objc private func playAgainTapped() {
        dismiss(animated: true) { [weak self] in
            self?.onPlayAgain?()
        }
    }

    @objc private func exitToMenuTapped() {
        dismiss(animated: true) { [weak self] in
            self?.onExitToMenu?()
        }
    }
}
