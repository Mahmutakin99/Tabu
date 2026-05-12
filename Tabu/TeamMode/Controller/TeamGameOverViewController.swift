//
//  TeamGameOverViewController.swift
//  Tabu
//
//  Created by MAHMUT AKIN on 13/10/2025.
//

import UIKit

final class TeamGameOverViewController: UIViewController {

    private let teams: [Team]
    var onPlayAgain: (() -> Void)?
    var onExitToMenu: (() -> Void)?

    private let backgroundView = GradientBackgroundView(colors: Palette.gameGradientColors)
    private var emitter: CAEmitterLayer?
    private var podiumBars: [UIView] = []

    init(teams: [Team]) {
        self.teams = teams.sorted { $0.score > $1.score }
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupBackground()
        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        playEntrance()
        startConfetti()
        Haptics.shared.success()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        emitter?.removeFromSuperlayer()
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
        let titleLabel = UILabel()
        titleLabel.text = "Oyun Bitti!"
        titleLabel.font = UIFont.scaled(.bold, size: 36, relativeTo: .largeTitle)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textAlignment = .center

        let sorted = teams
        let winnerLabel = UILabel()
        winnerLabel.text = sorted.isEmpty ? "" : "🏆 \(sorted[0].name)"
        winnerLabel.font = UIFont.scaled(.semibold, size: 22, relativeTo: .title2)
        winnerLabel.textColor = sorted.isEmpty ? .label : sorted[0].color
        winnerLabel.textAlignment = .center
        winnerLabel.adjustsFontForContentSizeCategory = true

        let podiumContainer = makePodium(sorted: sorted)

        let playAgainButton = AnimatedActionButton(title: "Tekrar Oyna",
                                                    systemName: "arrow.clockwise",
                                                    color: sorted.first?.color ?? .systemIndigo)
        playAgainButton.addTarget(self, action: #selector(playAgainTapped), for: .touchUpInside)

        let exitButton = AnimatedActionButton(title: "Ana Menüye Dön",
                                               systemName: "house.fill",
                                               color: .systemGray)
        exitButton.addTarget(self, action: #selector(exitToMenuTapped), for: .touchUpInside)

        let buttonStack = UIStackView(arrangedSubviews: [playAgainButton, exitButton])
        buttonStack.axis = .vertical
        buttonStack.spacing = Spacing.m

        let mainStack = UIStackView(arrangedSubviews: [titleLabel, winnerLabel, podiumContainer, buttonStack])
        mainStack.axis = .vertical
        mainStack.spacing = Spacing.l
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(mainStack)

        NSLayoutConstraint.activate([
            mainStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Spacing.xl),
            mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.xl),
            playAgainButton.heightAnchor.constraint(equalToConstant: 56),
            exitButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    private func makePodium(sorted: [Team]) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let maxScore = sorted.first.map { CGFloat(max($0.score, 1)) } ?? 1
        let maxHeight: CGFloat = 100
        let minHeight: CGFloat = 30

        var barViews: [UIView] = []
        var nameLabels: [UILabel] = []
        var scoreLabels: [UILabel] = []

        for (i, team) in sorted.enumerated() {
            let fraction = i == 0 ? 1.0 : CGFloat(max(team.score, 0)) / maxScore
            let barH = max(minHeight, maxHeight * fraction)

            let bar = UIView()
            bar.backgroundColor = team.color
            bar.layer.cornerRadius = Radius.chip
            bar.translatesAutoresizingMaskIntoConstraints = false
            bar.alpha = 0

            let nameLabel = UILabel()
            nameLabel.text = team.name
            nameLabel.font = UIFont.scaled(.semibold, size: 12, relativeTo: .caption1)
            nameLabel.adjustsFontForContentSizeCategory = true
            nameLabel.textAlignment = .center
            nameLabel.numberOfLines = 1
            nameLabel.translatesAutoresizingMaskIntoConstraints = false

            let scoreLabel = UILabel()
            scoreLabel.text = "\(team.score)"
            scoreLabel.font = UIFont.scaled(.bold, size: 14, relativeTo: .subheadline)
            scoreLabel.textColor = .white
            scoreLabel.textAlignment = .center
            scoreLabel.translatesAutoresizingMaskIntoConstraints = false

            container.addSubview(bar)
            container.addSubview(nameLabel)
            container.addSubview(scoreLabel)

            barViews.append(bar)
            nameLabels.append(nameLabel)
            scoreLabels.append(scoreLabel)

            NSLayoutConstraint.activate([
                bar.heightAnchor.constraint(equalToConstant: barH),
                bar.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -Spacing.l),
                scoreLabel.centerXAnchor.constraint(equalTo: bar.centerXAnchor),
                scoreLabel.centerYAnchor.constraint(equalTo: bar.centerYAnchor),
                nameLabel.centerXAnchor.constraint(equalTo: bar.centerXAnchor),
                nameLabel.bottomAnchor.constraint(equalTo: bar.topAnchor, constant: -Spacing.xs)
            ])
        }

        // Yatay dağılım
        let total = sorted.count
        if total > 0 {
            for (i, bar) in barViews.enumerated() {
                let width: CGFloat = 64
                bar.widthAnchor.constraint(equalToConstant: width).isActive = true
                if i == 0 {
                    bar.centerXAnchor.constraint(equalTo: container.centerXAnchor).isActive = true
                } else if i % 2 == 1 {
                    let gap = CGFloat((i + 1) / 2) * (width + Spacing.l)
                    bar.trailingAnchor.constraint(equalTo: barViews[0].leadingAnchor, constant: -gap + (width + Spacing.l)).isActive = true
                } else {
                    let gap = CGFloat(i / 2) * (width + Spacing.l)
                    bar.leadingAnchor.constraint(equalTo: barViews[0].trailingAnchor, constant: gap).isActive = true
                }
            }
        }

        container.heightAnchor.constraint(equalToConstant: maxHeight + Spacing.xxl + Spacing.l).isActive = true
        podiumBars = barViews
        return container
    }

    private func playEntrance() {
        for (i, bar) in podiumBars.enumerated() {
            UIView.animate(withDuration: 0.45, delay: Double(i) * 0.08,
                           usingSpringWithDamping: 0.7, initialSpringVelocity: 0.4) {
                bar.alpha = 1
            }
        }
    }

    private func startConfetti() {
        let layer = CAEmitterLayer()
        layer.emitterPosition = CGPoint(x: view.bounds.midX, y: -10)
        layer.emitterShape = .line
        layer.emitterSize = CGSize(width: view.bounds.width, height: 1)

        let colors: [UIColor] = [.systemYellow, .systemPink, .systemBlue, .systemGreen, .systemOrange]
        let cells = colors.map { confettiCell(color: $0) }
        layer.emitterCells = cells
        view.layer.addSublayer(layer)
        emitter = layer

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) { [weak layer] in
            layer?.birthRate = 0
        }
    }

    private func confettiCell(color: UIColor) -> CAEmitterCell {
        let cell = CAEmitterCell()
        cell.birthRate = 5
        cell.lifetime  = 4.0
        cell.velocity  = 200
        cell.velocityRange = 60
        cell.emissionLongitude = .pi
        cell.emissionRange = .pi / 4
        cell.spin = 3
        cell.spinRange = 4
        cell.scaleRange = 0.25
        cell.scale = 0.1
        cell.color = color.cgColor
        cell.contents = UIImage(systemName: "star.fill")?.withTintColor(color).cgImage
        return cell
    }

    @objc private func playAgainTapped() {
        dismiss(animated: true) { [weak self] in self?.onPlayAgain?() }
    }

    @objc private func exitToMenuTapped() {
        dismiss(animated: true) { [weak self] in self?.onExitToMenu?() }
    }
}
