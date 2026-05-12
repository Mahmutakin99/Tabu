//
//  MainMenuViewController.swift
//  Tabu
//
//  Created by MAHMUT AKIN on 13/10/2025.
//

import UIKit

final class MainMenuViewController: UIViewController {

    private var lastTeamSettings = TeamGameSettings.default()
    private var isLaunchingGame = false

    private let backgroundView = GradientBackgroundView(colors: Palette.menuGradientColors)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNav()
        setupBackground()
        setupUI()
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

    private func setupNav() {
        navigationItem.title = "Tabu"
        let gear = UIBarButtonItem(image: UIImage(systemName: "gearshape"),
                                   style: .plain,
                                   target: self,
                                   action: #selector(settingsTapped))
        gear.accessibilityLabel = "Ayarlar"
        navigationItem.rightBarButtonItem = gear

        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.scaled(.bold, size: 20, relativeTo: .headline)
        ]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .white
    }

    private func setupUI() {
        let soloButton = AnimatedActionButton(title: "Tek Başına",
                                              systemName: "person.fill",
                                              color: UIColor.white.withAlphaComponent(0.22),
                                              hapticsEnabled: true)
        soloButton.setTitleColor(.white, for: .normal)
        soloButton.addTarget(self, action: #selector(startSoloTapped), for: .touchUpInside)
        soloButton.accessibilityLabel = "Tek başına oyunu başlat"
        soloButton.translatesAutoresizingMaskIntoConstraints = false

        let teamButton = AnimatedActionButton(title: "Takımlı",
                                              systemName: "person.3.fill",
                                              color: UIColor.white.withAlphaComponent(0.22),
                                              hapticsEnabled: true)
        teamButton.setTitleColor(.white, for: .normal)
        teamButton.addTarget(self, action: #selector(startTeamTapped), for: .touchUpInside)
        teamButton.accessibilityLabel = "Takımlı oyunu başlat"
        teamButton.translatesAutoresizingMaskIntoConstraints = false

        let buttonStack = UIStackView(arrangedSubviews: [soloButton, teamButton])
        buttonStack.axis = .vertical
        buttonStack.spacing = Spacing.l
        buttonStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(buttonStack)

        NSLayoutConstraint.activate([
            buttonStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            buttonStack.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: Spacing.xxl),
            buttonStack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: Spacing.xxl),
            buttonStack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -Spacing.xxl),
            buttonStack.widthAnchor.constraint(greaterThanOrEqualToConstant: 240),

            soloButton.heightAnchor.constraint(equalToConstant: 60),
            teamButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }

    @objc private func settingsTapped() {
        Haptics.shared.selection()
        let vc = SettingsViewController()
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .formSheet
        present(nav, animated: true)
    }

    @objc private func startSoloTapped() {
        guard isLaunchingGame == false else { return }
        isLaunchingGame = true

        fetchCardsForCurrentSelection { [weak self] cards in
            guard let self = self else { return }
            guard cards.isEmpty == false else {
                self.isLaunchingGame = false
                self.showEmptyDeckAlert()
                return
            }

            let gameVC = GameViewController(cards: cards, settings: .default())
            gameVC.modalPresentationStyle = .fullScreen
            gameVC.modalTransitionStyle = .crossDissolve
            self.present(gameVC, animated: true) {
                self.isLaunchingGame = false
            }
        }
    }

    @objc private func startTeamTapped() {
        Haptics.shared.selection()
        let setupVC = TeamSetupViewController()
        setupVC.initialSettings = lastTeamSettings
        setupVC.onStart = { [weak self] settings in
            guard let self = self else { return }
            guard self.isLaunchingGame == false else { return }
            self.lastTeamSettings = settings
            self.isLaunchingGame = true

            self.fetchCardsForCurrentSelection { [weak self] cards in
                guard let self = self else { return }
                guard cards.isEmpty == false else {
                    if let presented = self.presentedViewController {
                        presented.dismiss(animated: true) {
                            self.isLaunchingGame = false
                            self.showEmptyDeckAlert()
                        }
                    } else {
                        self.isLaunchingGame = false
                        self.showEmptyDeckAlert()
                    }
                    return
                }

                let teamGameVC = TeamGameViewController(settings: settings, cards: cards)
                teamGameVC.modalPresentationStyle = .fullScreen
                teamGameVC.modalTransitionStyle = .crossDissolve
                if let presented = self.presentedViewController {
                    presented.dismiss(animated: true) {
                        self.present(teamGameVC, animated: true) {
                            self.isLaunchingGame = false
                        }
                    }
                } else {
                    self.present(teamGameVC, animated: true) {
                        self.isLaunchingGame = false
                    }
                }
            }
        }
        let nav = UINavigationController(rootViewController: setupVC)
        nav.modalPresentationStyle = .formSheet
        present(nav, animated: true)
    }

    private func fetchCardsForCurrentSelection(completion: @escaping ([Card]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let cards = SettingsManager.shared.provideCards()
            DispatchQueue.main.async { completion(cards) }
        }
    }

    private func showEmptyDeckAlert() {
        let alert = UIAlertController(
            title: "Kart Bulunamadı",
            message: "Seçili kategori/zorluk filtresi için kart yok. Ayarlardan filtreyi güncelleyebilirsin.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Ayarları Aç", style: .default, handler: { [weak self] _ in
            self?.settingsTapped()
        }))
        alert.addAction(UIAlertAction(title: "Kapat", style: .cancel))
        present(alert, animated: true)
    }
}
