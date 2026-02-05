//
//  TeamRoundSummaryViewController.swift
//  Tabu
//
//  Created by MAHMUT AKIN on 13/10/2025.
//

import UIKit

final class TeamRoundSummaryViewController: UIViewController {
    
    private let teamName: String
    private let stats: RoundStats
    private let isLastRoundOverall: Bool
    
    var onContinue: (() -> Void)?
    
    init(teamName: String, stats: RoundStats, isLastRoundOverall: Bool) {
        self.teamName = teamName
        self.stats = stats
        self.isLastRoundOverall = isLastRoundOverall
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
    }
    
    private func setupUI() {
        let titleLabel = UILabel()
        titleLabel.text = "Tur Özeti"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 28)
        titleLabel.textAlignment = .center
        
        let teamLabel = UILabel()
        teamLabel.text = "Takım: \(teamName)"
        teamLabel.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        teamLabel.textAlignment = .center
        teamLabel.numberOfLines = 2
        
        let correctLabel = UILabel()
        correctLabel.text = "Doğru: \(stats.correct)"
        correctLabel.font = UIFont.systemFont(ofSize: 20)
        correctLabel.textAlignment = .center
        
        let tabuLabel = UILabel()
        tabuLabel.text = "Tabu: \(stats.tabu)"
        tabuLabel.font = UIFont.systemFont(ofSize: 20)
        tabuLabel.textAlignment = .center
        
        let passLabel = UILabel()
        passLabel.text = "Pas: \(stats.pass)"
        passLabel.font = UIFont.systemFont(ofSize: 20)
        passLabel.textAlignment = .center
        
        let stack = UIStackView(arrangedSubviews: [titleLabel, teamLabel, correctLabel, tabuLabel, passLabel])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        let continueButton = UIButton(type: .system)
        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.filled()
            config.title = isLastRoundOverall ? "Bitir" : "Sıradaki Takıma Geç"
            config.baseBackgroundColor = .systemBlue
            config.baseForegroundColor = .white
            config.cornerStyle = .large
            continueButton.configuration = config
            continueButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        } else {
            continueButton.setTitle(isLastRoundOverall ? "Bitir" : "Sıradaki Takıma Geç", for: .normal)
            continueButton.setTitleColor(.white, for: .normal)
            continueButton.backgroundColor = .systemBlue
            continueButton.layer.cornerRadius = 14
            continueButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
            continueButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
        }
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stack)
        view.addSubview(continueButton)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            continueButton.topAnchor.constraint(greaterThanOrEqualTo: stack.bottomAnchor, constant: 30),
            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            continueButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }
    
    @objc private func continueTapped() {
        onContinue?()
    }
}

