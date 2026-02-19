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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBlue
        setupNav()
        setupUI()
    }
    
    private func setupNav() {
        navigationItem.title = "Tabu"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Ayarlar", style: .plain, target: self, action: #selector(settingsTapped))
    }

    private func setupUI() {
        let titleLabel = UILabel()
        titleLabel.text = "Tabu Oyunu"
        titleLabel.font = UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: UIFont.boldSystemFont(ofSize: 40))
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let soloButton = UIButton(type: .system)
        soloButton.setTitle("Tek Başına", for: .normal)
        soloButton.titleLabel?.font = UIFontMetrics(forTextStyle: .title2).scaledFont(for: UIFont.systemFont(ofSize: 24, weight: .bold))
        soloButton.titleLabel?.adjustsFontForContentSizeCategory = true
        soloButton.backgroundColor = .white
        soloButton.setTitleColor(.systemBlue, for: .normal)
        soloButton.layer.cornerRadius = 10
        soloButton.addTarget(self, action: #selector(startSoloTapped), for: .touchUpInside)
        soloButton.translatesAutoresizingMaskIntoConstraints = false
        soloButton.accessibilityLabel = "Tek başına oyunu başlat"
        
        let teamButton = UIButton(type: .system)
        teamButton.setTitle("Takımlı", for: .normal)
        teamButton.titleLabel?.font = UIFontMetrics(forTextStyle: .title2).scaledFont(for: UIFont.systemFont(ofSize: 24, weight: .bold))
        teamButton.titleLabel?.adjustsFontForContentSizeCategory = true
        teamButton.backgroundColor = .white
        teamButton.setTitleColor(.systemBlue, for: .normal)
        teamButton.layer.cornerRadius = 10
        teamButton.addTarget(self, action: #selector(startTeamTapped), for: .touchUpInside)
        teamButton.translatesAutoresizingMaskIntoConstraints = false
        teamButton.accessibilityLabel = "Takımlı oyunu başlat"

        view.addSubview(titleLabel)
        view.addSubview(soloButton)
        view.addSubview(teamButton)

        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -140),

            soloButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            soloButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 80),
            soloButton.widthAnchor.constraint(equalToConstant: 220),
            soloButton.heightAnchor.constraint(equalToConstant: 60),
            
            teamButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            teamButton.topAnchor.constraint(equalTo: soloButton.bottomAnchor, constant: 20),
            teamButton.widthAnchor.constraint(equalToConstant: 220),
            teamButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }

    @objc private func settingsTapped() {
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
            self.present(gameVC, animated: true) {
                self.isLaunchingGame = false
            }
        }
    }
    
    @objc private func startTeamTapped() {
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
        present(nav, animated: true, completion: nil)
    }
    
    private func fetchCardsForCurrentSelection(completion: @escaping ([Card]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let cards = SettingsManager.shared.provideCards()
            DispatchQueue.main.async {
                completion(cards)
            }
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
