//
//  TeamRoundSummaryViewController.swift
//  Tabu
//
//  Created by MAHMUT AKIN on 13/10/2025.
//

import UIKit

final class TeamRoundSummaryViewController: UIViewController {

    private let teamName: String
    private let teamColor: UIColor
    private let stats: RoundStats
    private let isLastRoundOverall: Bool

    var onContinue: (() -> Void)?

    init(teamName: String,
         teamColor: UIColor = .systemBlue,
         stats: RoundStats,
         isLastRoundOverall: Bool) {
        self.teamName = teamName
        self.teamColor = teamColor
        self.stats = stats
        self.isLastRoundOverall = isLastRoundOverall
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    private var statRows: [UIView] = []
    private let continueButton = AnimatedActionButton(title: "", systemName: "", color: .systemBlue)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupBackground()
        setupNav()
        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        playEntranceAnimation()
        Haptics.shared.success()
    }

    private func setupBackground() {
        let bg = GradientBackgroundView(colors: Palette.gameGradientColors)
        bg.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(bg, at: 0)
        NSLayoutConstraint.activate([
            bg.topAnchor.constraint(equalTo: view.topAnchor),
            bg.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bg.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bg.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupNav() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark.circle.fill"),
            style: .plain,
            target: self,
            action: #selector(closeTapped)
        )
        navigationItem.rightBarButtonItem?.tintColor = .secondaryLabel
    }

    private func setupUI() {
        let titleLabel = makeLabel("Tur Özeti",
                                   font: UIFont.scaled(.bold, size: 28, relativeTo: .title1),
                                   color: .label, alignment: .center)

        // Team badge
        let badgeContainer = UIView()
        badgeContainer.backgroundColor = teamColor.withAlphaComponent(0.18)
        badgeContainer.layer.cornerRadius = Radius.badge
        let badgeLabel = makeLabel(teamName,
                                    font: UIFont.scaled(.semibold, size: 16, relativeTo: .subheadline),
                                    color: teamColor, alignment: .center)
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        badgeContainer.addSubview(badgeLabel)
        NSLayoutConstraint.activate([
            badgeLabel.topAnchor.constraint(equalTo: badgeContainer.topAnchor, constant: Spacing.xs),
            badgeLabel.bottomAnchor.constraint(equalTo: badgeContainer.bottomAnchor, constant: -Spacing.xs),
            badgeLabel.leadingAnchor.constraint(equalTo: badgeContainer.leadingAnchor, constant: Spacing.m),
            badgeLabel.trailingAnchor.constraint(equalTo: badgeContainer.trailingAnchor, constant: -Spacing.m)
        ])

        let badgeRow = UIStackView(arrangedSubviews: [badgeContainer])
        badgeRow.axis = .horizontal
        badgeRow.alignment = .center

        let correctRow  = makeStatRow(icon: "checkmark.circle.fill", color: .systemGreen, text: "Doğru", value: stats.correct)
        let tabuRow     = makeStatRow(icon: "xmark.octagon.fill",     color: .systemRed,   text: "Tabu",  value: stats.tabu)
        let passRow     = makeStatRow(icon: "arrow.right.circle.fill",color: .systemOrange,text: "Pas",   value: stats.pass)

        statRows = [correctRow, tabuRow, passRow]

        let statCard = UIView()
        statCard.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.72)
        statCard.layer.cornerRadius = Radius.card
        Shadow.elevated.apply(to: statCard.layer)

        let statStack = UIStackView(arrangedSubviews: [correctRow, tabuRow, passRow])
        statStack.axis = .vertical
        statStack.spacing = Spacing.m
        statStack.translatesAutoresizingMaskIntoConstraints = false
        statCard.addSubview(statStack)
        NSLayoutConstraint.activate([
            statStack.topAnchor.constraint(equalTo: statCard.topAnchor, constant: Spacing.l),
            statStack.leadingAnchor.constraint(equalTo: statCard.leadingAnchor, constant: Spacing.l),
            statStack.trailingAnchor.constraint(equalTo: statCard.trailingAnchor, constant: -Spacing.l),
            statStack.bottomAnchor.constraint(equalTo: statCard.bottomAnchor, constant: -Spacing.l)
        ])

        // Continue button
        let btnTitle = isLastRoundOverall ? "Bitir" : "Sıradaki Takım"
        let btnIcon  = isLastRoundOverall ? "flag.checkered" : "arrow.right"
        let btn = AnimatedActionButton(title: btnTitle, systemName: btnIcon, color: teamColor)
        btn.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false

        let mainStack = UIStackView(arrangedSubviews: [titleLabel, badgeRow, statCard])
        mainStack.axis = .vertical
        mainStack.spacing = Spacing.l
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(mainStack)
        view.addSubview(btn)

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Spacing.xl),
            mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Spacing.xl),
            mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.xl),

            btn.topAnchor.constraint(greaterThanOrEqualTo: mainStack.bottomAnchor, constant: Spacing.xl),
            btn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Spacing.xl),
            btn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.xl),
            btn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -Spacing.l),
            btn.heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    private func makeLabel(_ text: String,
                            font: UIFont,
                            color: UIColor,
                            alignment: NSTextAlignment = .natural) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = font
        l.adjustsFontForContentSizeCategory = true
        l.textColor = color
        l.textAlignment = alignment
        l.numberOfLines = 0
        return l
    }

    private func makeStatRow(icon: String, color: UIColor, text: String, value: Int) -> UIView {
        let img = UIImageView(image: UIImage(systemName: icon))
        img.tintColor = color
        img.contentMode = .scaleAspectFit
        img.translatesAutoresizingMaskIntoConstraints = false
        img.widthAnchor.constraint(equalToConstant: 24).isActive = true
        img.heightAnchor.constraint(equalToConstant: 24).isActive = true

        let nameLabel = makeLabel(text,
                                   font: UIFont.scaled(.regular, size: 18, relativeTo: .body),
                                   color: .label)
        let valueLabel = makeLabel("\(value)",
                                    font: UIFont.scaled(.bold, size: 22, relativeTo: .title3),
                                    color: color, alignment: .right)

        let row = UIStackView(arrangedSubviews: [img, nameLabel, valueLabel])
        row.axis = .horizontal
        row.spacing = Spacing.m
        row.alignment = .center
        nameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        valueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        return row
    }

    private func playEntranceAnimation() {
        for (i, row) in statRows.enumerated() {
            row.alpha = 0
            row.transform = CGAffineTransform(translationX: 30, y: 0)
            UIView.animate(withDuration: 0.35, delay: 0.1 + Double(i) * 0.06,
                           usingSpringWithDamping: 0.75, initialSpringVelocity: 0.5) {
                row.alpha = 1
                row.transform = .identity
            }
        }
    }

    @objc private func continueTapped() {
        onContinue?()
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
        onContinue?()
    }
}
