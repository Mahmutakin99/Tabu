//
//  GameOverViewController.swift
//  Tabu
//
//  Created by MAHMUT AKIN on 13/10/2025.
//

import UIKit

final class GameOverViewController: UIViewController {

    var finalScore: Int = 0
    var onPlayAgain: (() -> Void)?
    var onExitToMenu: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemRed
        setupUI()
    }

    private func setupUI() {
        let gameOverLabel = UILabel()
        gameOverLabel.text = "Süre Doldu!"
        gameOverLabel.font = UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: UIFont.boldSystemFont(ofSize: 40))
        gameOverLabel.adjustsFontForContentSizeCategory = true
        gameOverLabel.textColor = .white
        gameOverLabel.textAlignment = .center
        gameOverLabel.translatesAutoresizingMaskIntoConstraints = false

        let scoreLabel = UILabel()
        scoreLabel.text = "Skorunuz: \(finalScore)"
        scoreLabel.font = UIFontMetrics(forTextStyle: .title1).scaledFont(for: UIFont.systemFont(ofSize: 30))
        scoreLabel.adjustsFontForContentSizeCategory = true
        scoreLabel.textColor = .white
        scoreLabel.textAlignment = .center
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false

        let playAgainButton = makeButton(title: "Tekrar Oyna", action: #selector(playAgainTapped))
        playAgainButton.accessibilityLabel = "Tekrar oyna"

        let exitButton = makeButton(title: "Ana Menüye Dön", action: #selector(exitToMenuTapped))
        exitButton.accessibilityLabel = "Ana menüye dön"

        let buttonStack = UIStackView(arrangedSubviews: [playAgainButton, exitButton])
        buttonStack.axis = .vertical
        buttonStack.spacing = 16
        buttonStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(gameOverLabel)
        view.addSubview(scoreLabel)
        view.addSubview(buttonStack)

        NSLayoutConstraint.activate([
            gameOverLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            gameOverLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -120),

            scoreLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scoreLabel.topAnchor.constraint(equalTo: gameOverLabel.bottomAnchor, constant: 20),

            buttonStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            buttonStack.topAnchor.constraint(equalTo: scoreLabel.bottomAnchor, constant: 60),
            buttonStack.widthAnchor.constraint(equalToConstant: 220),

            playAgainButton.heightAnchor.constraint(equalToConstant: 60),
            exitButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }

    private func makeButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFontMetrics(forTextStyle: .title2).scaledFont(for: UIFont.systemFont(ofSize: 20, weight: .bold))
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.backgroundColor = .white
        button.setTitleColor(.systemRed, for: .normal)
        button.layer.cornerRadius = 10
        button.addTarget(self, action: action, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
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
