//
//  SettingsViewController.swift
//  Tabu
//
//  Created by MAHMUT AKIN on 14/10/2025.
//

import UIKit

final class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private enum Section: Int, CaseIterable {
        case categories
        case difficulties
    }
    
    private static let cellReuseID = "SettingsCell"
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    private var isLoadingCategories = true
    private var allCategories: [String] = []
    private var selectedCategories: Set<String> = []
    private var selectedDifficulties: Set<CardDifficulty> = Set(CardDifficulty.allCases)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Genel Ayarlar"
        view.backgroundColor = .systemBackground
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Kapat", style: .plain, target: self, action: #selector(closeTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Kaydet", style: .done, target: self, action: #selector(saveTapped))
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.cellReuseID)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.allowsMultipleSelection = false
        tableView.estimatedRowHeight = 52
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        updateLoadingStateUI()
        loadCategoriesAndSelection()
    }
    
    private func loadCategoriesAndSelection() {
        isLoadingCategories = true
        updateLoadingStateUI()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let categories = WordProvider.shared.categories()
            DispatchQueue.main.async {
                self.allCategories = categories
                self.loadSelection()
                self.isLoadingCategories = false
                self.updateLoadingStateUI()
                self.tableView.reloadData()
                if categories.isEmpty {
                    self.showCatalogLoadErrorAlert()
                }
            }
        }
    }
    
    private func loadSelection() {
        if let saved = SettingsManager.shared.selectedCategories, saved.isEmpty == false {
            selectedCategories = Set(saved).intersection(allCategories)
        } else {
            // Varsayılan: hepsi seçili
            selectedCategories = Set(allCategories)
        }
        if selectedCategories.isEmpty {
            selectedCategories = Set(allCategories)
        }
        
        if let savedDifficulties = SettingsManager.shared.selectedDifficulties, savedDifficulties.isEmpty == false {
            selectedDifficulties = Set(savedDifficulties)
        } else {
            selectedDifficulties = Set(CardDifficulty.allCases)
        }
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    @objc private func saveTapped() {
        guard isLoadingCategories == false else {
            showValidationAlert(message: "Kategoriler yüklenirken lütfen bekle.")
            return
        }
        guard allCategories.isEmpty == false else {
            showValidationAlert(message: "Katalog yüklenemedi. Lütfen tekrar dene.")
            return
        }
        guard selectedCategories.isEmpty == false else {
            showValidationAlert(message: "En az bir kategori seçmelisin.")
            return
        }
        guard selectedDifficulties.isEmpty == false else {
            showValidationAlert(message: "En az bir zorluk seviyesi seçmelisin.")
            return
        }
        
        SettingsManager.shared.selectedCategories = Array(selectedCategories).sorted()
        SettingsManager.shared.selectedDifficulties = selectedDifficulties.sorted { $0.rawValue < $1.rawValue }
        dismiss(animated: true)
    }
    
    private func showValidationAlert(message: String) {
        let alert = UIAlertController(title: "Eksik Seçim", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default))
        present(alert, animated: true)
    }
    
    private func showCatalogLoadErrorAlert() {
        let alert = UIAlertController(
            title: "Katalog Yüklenemedi",
            message: "Kelime listesi şu an okunamadı. Bağlamı yenileyip tekrar deneyebilirsin.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Tekrar Dene", style: .default, handler: { [weak self] _ in
            self?.loadCategoriesAndSelection()
        }))
        alert.addAction(UIAlertAction(title: "Kapat", style: .cancel))
        present(alert, animated: true)
    }
    
    private func updateLoadingStateUI() {
        if isLoadingCategories {
            loadingIndicator.startAnimating()
            tableView.backgroundView = loadingIndicator
        } else {
            loadingIndicator.stopAnimating()
            tableView.backgroundView = nil
        }
        
        navigationItem.rightBarButtonItem?.isEnabled = (isLoadingCategories == false && allCategories.isEmpty == false)
    }
    
    // MARK: Table
    
    func numberOfSections(in tableView: UITableView) -> Int { Section.allCases.count }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isLoadingCategories {
            return 0
        }
        
        switch Section(rawValue: section)! {
        case .categories:
            return allCategories.count
        case .difficulties:
            return CardDifficulty.allCases.count
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section)! {
        case .categories:
            return "Kategoriler (çoklu seçim)"
        case .difficulties:
            return "Zorluk Seviyesi (çoklu seçim)"
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Self.cellReuseID, for: indexPath)
        
        switch Section(rawValue: indexPath.section)! {
        case .categories:
            guard allCategories.indices.contains(indexPath.row) else { return cell }
            let category = allCategories[indexPath.row]
            cell.textLabel?.text = category
            cell.accessoryType = selectedCategories.contains(category) ? .checkmark : .none
        case .difficulties:
            let difficulty = CardDifficulty.allCases[indexPath.row]
            cell.textLabel?.text = difficulty.title
            cell.accessoryType = selectedDifficulties.contains(difficulty) ? .checkmark : .none
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard isLoadingCategories == false else { return }
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch Section(rawValue: indexPath.section)! {
        case .categories:
            let category = allCategories[indexPath.row]
            if selectedCategories.contains(category) {
                selectedCategories.remove(category)
            } else {
                selectedCategories.insert(category)
            }
            if let cell = tableView.cellForRow(at: indexPath) {
                cell.accessoryType = selectedCategories.contains(category) ? .checkmark : .none
            }
        case .difficulties:
            let difficulty = CardDifficulty.allCases[indexPath.row]
            if selectedDifficulties.contains(difficulty) {
                selectedDifficulties.remove(difficulty)
            } else {
                selectedDifficulties.insert(difficulty)
            }
            if let cell = tableView.cellForRow(at: indexPath) {
                cell.accessoryType = selectedDifficulties.contains(difficulty) ? .checkmark : .none
            }
        }
    }
}
