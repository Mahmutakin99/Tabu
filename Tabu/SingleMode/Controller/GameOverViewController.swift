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
        
        let playAgainButton = UIButton(type: .system)
        playAgainButton.setTitle("Tekrar Oyna", for: .normal)
        playAgainButton.titleLabel?.font = UIFontMetrics(forTextStyle: .title2).scaledFont(for: UIFont.systemFont(ofSize: 24, weight: .bold))
        playAgainButton.titleLabel?.adjustsFontForContentSizeCategory = true
        playAgainButton.backgroundColor = .white
        playAgainButton.setTitleColor(.systemRed, for: .normal)
        playAgainButton.layer.cornerRadius = 10
        playAgainButton.addTarget(self, action: #selector(playAgainTapped), for: .touchUpInside)
        playAgainButton.translatesAutoresizingMaskIntoConstraints = false
        playAgainButton.accessibilityLabel = "Tekrar oyna"

        view.addSubview(gameOverLabel)
        view.addSubview(scoreLabel)
        view.addSubview(playAgainButton)

        NSLayoutConstraint.activate([
            gameOverLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            gameOverLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -100),

            scoreLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scoreLabel.topAnchor.constraint(equalTo: gameOverLabel.bottomAnchor, constant: 20),

            playAgainButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playAgainButton.topAnchor.constraint(equalTo: scoreLabel.bottomAnchor, constant: 100),
            playAgainButton.widthAnchor.constraint(equalToConstant: 200),
            playAgainButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }

    @objc private func playAgainTapped() {
        dismiss(animated: true) { [weak self] in
            self?.onPlayAgain?()
        }
    }
}
