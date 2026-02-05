//
//  TeamSetupViewController.swift
//  Tabu
//
//  Created by MAHMUT AKIN on 13/10/2025.
//

import UIKit

final class TeamSetupViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    
    var initialSettings = TeamGameSettings.default()
    var onStart: ((TeamGameSettings) -> Void)?
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    // Bu şekilde olacak
    // Section modeli:
    // 0: Takım sayısı
    // 1: Takım adları
    // 2: Tur Süresi
    // 3: Pas
    // 4: Tur Sayısı (roundsPerTeam)
    private enum Section: Int, CaseIterable {
        case teamCount, teamNames, roundTime, pass, roundsPerTeam
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Takım Kurulumu"
        //takımlı mod ayarlama görünümü
        view.backgroundColor = .systemBackground
        
        let rightStyle: UIBarButtonItem.Style
        if #available(iOS 26.0, *) {
            rightStyle = .prominent
        } else {
            rightStyle = .done
        }
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Başla", style: rightStyle, target: self, action: #selector(startTapped))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Kapat", style: .plain, target: self, action: #selector(closeTapped))
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.keyboardDismissMode = .onDrag
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func startTapped() {
        // Temiz isim listesi (boş ise varsayılan isim ata)
        for i in 0..<initialSettings.teamCount {
            if initialSettings.teamNames.indices.contains(i) == false {
                initialSettings.teamNames.append("Takım \(i+1)")
            } else if initialSettings.teamNames[i].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                initialSettings.teamNames[i] = "Takım \(i+1)"
            }
        }
        onStart?(initialSettings)
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Table
    
    func numberOfSections(in tableView: UITableView) -> Int { Section.allCases.count }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .teamCount:
            return 1
        case .teamNames:
            return initialSettings.teamCount
        case .roundTime:
            return 1
        case .pass:
            return 2 // Sınırsız switch + limit stepper
        case .roundsPerTeam:
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section)! {
        case .teamCount: return "Takım Sayısı"
        case .teamNames: return "Takım Adları"
        case .roundTime: return "Tur Süresi (sn)"
        case .pass: return "Pas Hakkı"
        case .roundsPerTeam: return "Tur Sayısı (Takım Başına)"
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section)! {
        case .teamCount:
            let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
            cell.textLabel?.text = "Takımlar"
            let stepper = UIStepper()
            stepper.minimumValue = 2
            stepper.maximumValue = 6
            stepper.value = Double(initialSettings.teamCount)
            stepper.addTarget(self, action: #selector(teamCountChanged(_:)), for: .valueChanged)
            cell.accessoryView = stepper
            cell.detailTextLabel?.text = "\(initialSettings.teamCount)"
            return cell
            
        case .teamNames:
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            let tf = UITextField(frame: .zero)
            tf.placeholder = "Takım \(indexPath.row + 1)"
            tf.text = initialSettings.teamNames.indices.contains(indexPath.row) ? initialSettings.teamNames[indexPath.row] : ""
            tf.delegate = self
            tf.tag = 10_000 + indexPath.row
            tf.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(tf)
            NSLayoutConstraint.activate([
                tf.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
                tf.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
                tf.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8),
                tf.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -8),
                tf.heightAnchor.constraint(equalToConstant: 36)
            ])
            return cell
            
        case .roundTime:
            let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
            cell.textLabel?.text = "Süre"
            cell.detailTextLabel?.text = "\(initialSettings.roundTimeSeconds) sn"
            let stepper = UIStepper()
            stepper.minimumValue = 20
            stepper.maximumValue = 180
            stepper.stepValue = 10
            stepper.value = Double(initialSettings.roundTimeSeconds)
            stepper.addTarget(self, action: #selector(roundTimeChanged(_:)), for: .valueChanged)
            cell.accessoryView = stepper
            return cell
            
        case .pass:
            if indexPath.row == 0 {
                // Sınırsız Pas
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                cell.textLabel?.text = "Sınırsız Pas"
                let sw = UISwitch()
                sw.isOn = initialSettings.isPassUnlimited
                sw.addTarget(self, action: #selector(passUnlimitedChanged(_:)), for: .valueChanged)
                cell.accessoryView = sw
                return cell
            } else {
                // Limit
                let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
                cell.textLabel?.text = "Pas Limiti"
                cell.detailTextLabel?.text = initialSettings.isPassUnlimited ? "Sınırsız" : "\(initialSettings.passLimit)"
                let stepper = UIStepper()
                stepper.minimumValue = 0
                stepper.maximumValue = 10
                stepper.stepValue = 1
                stepper.value = Double(initialSettings.passLimit)
                stepper.isEnabled = !initialSettings.isPassUnlimited
                stepper.addTarget(self, action: #selector(passLimitChanged(_:)), for: .valueChanged)
                cell.accessoryView = stepper
                return cell
            }
            
        case .roundsPerTeam:
            let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
            cell.textLabel?.text = "Tur Sayısı"
            cell.detailTextLabel?.text = "\(initialSettings.roundsPerTeam)"
            let stepper = UIStepper()
            stepper.minimumValue = 2
            stepper.maximumValue = 5
            stepper.stepValue = 1
            stepper.value = Double(initialSettings.roundsPerTeam)
            stepper.addTarget(self, action: #selector(roundsPerTeamChanged(_:)), for: .valueChanged)
            cell.accessoryView = stepper
            return cell
        }
    }
    
    // MARK: - Handlers
    
    @objc private func teamCountChanged(_ sender: UIStepper) {
        initialSettings.teamCount = Int(sender.value)
        // İsim dizisini yeni sayıya göre ayarla
        if initialSettings.teamNames.count < initialSettings.teamCount {
            let start = initialSettings.teamNames.count
            for i in start..<initialSettings.teamCount {
                initialSettings.teamNames.append("Takım \(i+1)")
            }
        } else if initialSettings.teamNames.count > initialSettings.teamCount {
            initialSettings.teamNames = Array(initialSettings.teamNames.prefix(initialSettings.teamCount))
        }
        tableView.reloadSections(IndexSet(integer: Section.teamNames.rawValue), with: .automatic)
        tableView.reloadRows(at: [IndexPath(row: 0, section: Section.teamCount.rawValue)], with: .none)
    }
    
    @objc private func roundTimeChanged(_ sender: UIStepper) {
        initialSettings.roundTimeSeconds = Int(sender.value)
        tableView.reloadRows(at: [IndexPath(row: 0, section: Section.roundTime.rawValue)], with: .none)
    }
    
    @objc private func passUnlimitedChanged(_ sender: UISwitch) {
        initialSettings.isPassUnlimited = sender.isOn
        tableView.reloadSections(IndexSet(integer: Section.pass.rawValue), with: .automatic)
    }
    
    @objc private func passLimitChanged(_ sender: UIStepper) {
        initialSettings.passLimit = Int(sender.value)
        tableView.reloadRows(at: [IndexPath(row: 1, section: Section.pass.rawValue)], with: .none)
    }
    
    @objc private func roundsPerTeamChanged(_ sender: UIStepper) {
        initialSettings.roundsPerTeam = Int(sender.value)
        tableView.reloadRows(at: [IndexPath(row: 0, section: Section.roundsPerTeam.rawValue)], with: .none)
    }
    
    // MARK: - TextField
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        let idx = textField.tag - 10_000
        guard idx >= 0 else { return }
        if initialSettings.teamNames.indices.contains(idx) {
            initialSettings.teamNames[idx] = textField.text ?? ""
        } else if idx < initialSettings.teamCount {
            initialSettings.teamNames.append(textField.text ?? "")
        }
    }
}

