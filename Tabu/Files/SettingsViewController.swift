//
//  SettingsViewController.swift
//  Tabu
//
//  Created by MAHMUT AKIN on 14/10/2025.
//

import UIKit

final class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private static let cellReuseID = "CategoryCell"
    private static var cachedCategories: [String]? = nil
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var allCategories: [String] = []
    private var selected: Set<String> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Genel Ayarlar"
        view.backgroundColor = .systemBackground
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Kapat", style: .plain, target: self, action: #selector(closeTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Kaydet", style: .prominent, target: self, action: #selector(saveTapped))
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.cellReuseID)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        loadCategoriesAndSelection()
    }
    
    private func loadCategoriesAndSelection() {
        // Use cache if available to avoid repeated disk I/O
        if let cache = Self.cachedCategories {
            self.allCategories = cache
            self.loadSelection()
            self.tableView.reloadData()
            return
        }
        // Load from bundle off the main thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            var categories: [String] = []
            if let url = Bundle.main.url(forResource: "Kelimeler", withExtension: "json"),
               let data = try? Data(contentsOf: url),
               let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                categories = Array(dict.keys).sorted()
            }
            DispatchQueue.main.async {
                Self.cachedCategories = categories
                self.allCategories = categories
                self.loadSelection()
                self.tableView.reloadData()
            }
        }
    }
    
    private func loadSelection() {
        if let saved = SettingsManager.shared.selectedCategories {
            selected = Set(saved)
        } else {
            // Varsayılan: hepsi seçili
            selected = Set(allCategories)
        }
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    @objc private func saveTapped() {
        SettingsManager.shared.selectedCategories = Array(selected)
        dismiss(animated: true)
    }
    
    // MARK: Table
    
    func numberOfSections(in tableView: UITableView) -> Int { 1 }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { allCategories.count }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        "Kategoriler (çoklu seçim)"
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cat = allCategories[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: Self.cellReuseID, for: indexPath)
        cell.textLabel?.text = cat
        cell.accessoryType = selected.contains(cat) ? .checkmark : .none
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let cat = allCategories[indexPath.row]
        if selected.contains(cat) {
            selected.remove(cat)
        } else {
            selected.insert(cat)
        }
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = selected.contains(cat) ? .checkmark : .none
        }
    }
}

