//
//  TeamSetupViewController.swift
//  Tabu
//
//  Created by MAHMUT AKIN on 13/10/2025.
//

import UIKit

final class TeamSetupViewController: UIViewController,
                                     UITableViewDataSource,
                                     UITableViewDelegate,
                                     UITextFieldDelegate {

    var initialSettings = TeamGameSettings.default()
    var onStart: ((TeamGameSettings) -> Void)?

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    private enum Section: Int, CaseIterable {
        case teamCount, teamNames, roundTime, pass, roundsPerTeam
    }

    private static let stepperCellID  = "StepperCell"
    private static let switchCellID   = "SwitchCell"
    private static let textFieldCellID = "TextFieldCell"

    // Takım renkleri (initialSettings ile paralel, index → color)
    private var teamColors: [UIColor] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Takım Kurulumu"
        view.backgroundColor = .systemBackground

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Başla", style: .done,
                                                             target: self, action: #selector(startTapped))
        navigationItem.leftBarButtonItem  = UIBarButtonItem(title: "Kapat", style: .plain,
                                                             target: self, action: #selector(closeTapped))

        syncTeamColors()

        tableView.dataSource = self
        tableView.delegate   = self
        tableView.keyboardDismissMode = .onDrag
        // stepperCellID → .value1 style; register sadece switch + textField için
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.switchCellID)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.textFieldCellID)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Helpers

    private func syncTeamColors() {
        while teamColors.count < initialSettings.teamCount {
            let i = teamColors.count
            let colorIndex = initialSettings.teamColorIndices.indices.contains(i)
                ? initialSettings.teamColorIndices[i]
                : i % Palette.teamColors.count
            teamColors.append(Palette.teamColors[colorIndex % Palette.teamColors.count])
        }
        if teamColors.count > initialSettings.teamCount {
            teamColors = Array(teamColors.prefix(initialSettings.teamCount))
        }
    }

    private func timeString(_ seconds: Int) -> String {
        seconds >= 60 ? "\(seconds / 60):\(String(format: "%02d", seconds % 60))" : "\(seconds) sn"
    }

    private func estimatedMinutes() -> Int {
        let totalSeconds = initialSettings.teamCount * initialSettings.roundsPerTeam * initialSettings.roundTimeSeconds
        return max(1, totalSeconds / 60)
    }

    // MARK: - Actions

    @objc private func startTapped() {
        for i in 0..<initialSettings.teamCount {
            if initialSettings.teamNames.indices.contains(i) == false {
                initialSettings.teamNames.append("Takım \(i + 1)")
            } else if initialSettings.teamNames[i].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                initialSettings.teamNames[i] = "Takım \(i + 1)"
            }
        }
        initialSettings.teamColorIndices = teamColors.prefix(initialSettings.teamCount).map { color in
            Palette.teamColors.firstIndex(of: color) ?? 0
        }
        onStart?(initialSettings)
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    // MARK: - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int { Section.allCases.count }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sec = Section(rawValue: section) else { return 0 }
        switch sec {
        case .teamCount:    return 1
        case .teamNames:    return initialSettings.teamCount
        case .roundTime:    return 1
        case .pass:         return 2
        case .roundsPerTeam: return 1
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let sec = Section(rawValue: section) else { return nil }
        switch sec {
        case .teamCount:     return "Takım Sayısı"
        case .teamNames:     return "Takım Adları"
        case .roundTime:     return "Tur Süresi"
        case .pass:          return "Pas Hakkı"
        case .roundsPerTeam: return "Tur Sayısı (Takım Başına)"
        }
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard Section(rawValue: section) == .roundsPerTeam else { return nil }
        return "Tahmini süre: ~\(estimatedMinutes()) dk"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let sec = Section(rawValue: indexPath.section) else { return UITableViewCell() }

        switch sec {

        case .teamCount:
            let cell = tableView.dequeueReusableCell(withIdentifier: Self.stepperCellID)
                ?? UITableViewCell(style: .value1, reuseIdentifier: Self.stepperCellID)
            cell.textLabel?.text = "Takımlar"
            cell.selectionStyle = .none
            let stepper = UIStepper()
            stepper.minimumValue = 2
            stepper.maximumValue = 6
            stepper.value = Double(initialSettings.teamCount)
            stepper.addTarget(self, action: #selector(teamCountChanged(_:)), for: .valueChanged)
            cell.accessoryView = stepper
            cell.detailTextLabel?.text = "\(initialSettings.teamCount)"
            return cell

        case .teamNames:
            let cell = tableView.dequeueReusableCell(withIdentifier: Self.textFieldCellID, for: indexPath)
            cell.selectionStyle = .none
            cell.contentView.subviews.forEach { $0.removeFromSuperview() }

            let colorDot = UIButton(type: .system)
            colorDot.tag = 20_000 + indexPath.row
            let dotColor = teamColors.indices.contains(indexPath.row)
                ? teamColors[indexPath.row]
                : Palette.teamColors[indexPath.row % Palette.teamColors.count]
            colorDot.backgroundColor = dotColor
            colorDot.layer.cornerRadius = 12
            colorDot.layer.masksToBounds = true
            colorDot.translatesAutoresizingMaskIntoConstraints = false
            colorDot.addTarget(self, action: #selector(colorDotTapped(_:)), for: .touchUpInside)

            let tf = UITextField()
            tf.placeholder = "Takım \(indexPath.row + 1)"
            tf.text = initialSettings.teamNames.indices.contains(indexPath.row)
                ? initialSettings.teamNames[indexPath.row] : ""
            tf.delegate = self
            tf.tag = 10_000 + indexPath.row
            tf.clearButtonMode = .whileEditing
            tf.autocapitalizationType = .words
            tf.returnKeyType = .done
            tf.translatesAutoresizingMaskIntoConstraints = false

            cell.contentView.addSubview(colorDot)
            cell.contentView.addSubview(tf)

            NSLayoutConstraint.activate([
                colorDot.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: Spacing.l),
                colorDot.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
                colorDot.widthAnchor.constraint(equalToConstant: 24),
                colorDot.heightAnchor.constraint(equalToConstant: 24),

                tf.leadingAnchor.constraint(equalTo: colorDot.trailingAnchor, constant: Spacing.m),
                tf.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -Spacing.l),
                tf.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: Spacing.s),
                tf.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -Spacing.s),
                tf.heightAnchor.constraint(equalToConstant: 36)
            ])
            return cell

        case .roundTime:
            let cell = tableView.dequeueReusableCell(withIdentifier: Self.stepperCellID)
                ?? UITableViewCell(style: .value1, reuseIdentifier: Self.stepperCellID)
            cell.textLabel?.text = "Süre"
            cell.selectionStyle = .none
            cell.detailTextLabel?.text = timeString(initialSettings.roundTimeSeconds)
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
                let cell = tableView.dequeueReusableCell(withIdentifier: Self.switchCellID, for: indexPath)
                cell.textLabel?.text = "Sınırsız"
                cell.selectionStyle = .none
                let sw = UISwitch()
                sw.isOn = initialSettings.isPassUnlimited
                sw.addTarget(self, action: #selector(passUnlimitedChanged(_:)), for: .valueChanged)
                cell.accessoryView = sw
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: Self.stepperCellID)
                ?? UITableViewCell(style: .value1, reuseIdentifier: Self.stepperCellID)
                cell.textLabel?.text = "Pas Limiti"
                cell.selectionStyle = .none
                cell.detailTextLabel?.text = initialSettings.isPassUnlimited ? "Sınırsız" : "\(initialSettings.passLimit)"
                let stepper = UIStepper()
                stepper.minimumValue = 0
                stepper.maximumValue = 10
                stepper.stepValue = 1
                stepper.value = Double(initialSettings.passLimit)
                stepper.isEnabled = !initialSettings.isPassUnlimited
                stepper.addTarget(self, action: #selector(passLimitChanged(_:)), for: .valueChanged)
                cell.accessoryView = stepper
                UIView.animate(withDuration: 0.2) {
                    cell.alpha = self.initialSettings.isPassUnlimited ? 0.4 : 1.0
                }
                return cell
            }

        case .roundsPerTeam:
            let cell = tableView.dequeueReusableCell(withIdentifier: Self.stepperCellID)
                ?? UITableViewCell(style: .value1, reuseIdentifier: Self.stepperCellID)
            cell.textLabel?.text = "Tur Sayısı"
            cell.selectionStyle = .none
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

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: - Steppers / Switches

    @objc private func teamCountChanged(_ sender: UIStepper) {
        let newCount = Int(sender.value)
        let oldCount = initialSettings.teamCount
        guard newCount != oldCount else { return }

        initialSettings.teamCount = newCount
        if initialSettings.teamNames.count < newCount {
            for i in initialSettings.teamNames.count..<newCount {
                initialSettings.teamNames.append("Takım \(i + 1)")
            }
        } else {
            initialSettings.teamNames = Array(initialSettings.teamNames.prefix(newCount))
        }
        syncTeamColors()

        tableView.performBatchUpdates {
            tableView.reloadRows(at: [IndexPath(row: 0, section: Section.teamCount.rawValue)], with: .none)
            if newCount > oldCount {
                let paths = (oldCount..<newCount).map { IndexPath(row: $0, section: Section.teamNames.rawValue) }
                tableView.insertRows(at: paths, with: .automatic)
            } else {
                let paths = (newCount..<oldCount).map { IndexPath(row: $0, section: Section.teamNames.rawValue) }
                tableView.deleteRows(at: paths, with: .automatic)
            }
            tableView.reloadSections(IndexSet(integer: Section.roundsPerTeam.rawValue), with: .none)
        }
    }

    @objc private func roundTimeChanged(_ sender: UIStepper) {
        initialSettings.roundTimeSeconds = Int(sender.value)
        tableView.reloadRows(at: [IndexPath(row: 0, section: Section.roundTime.rawValue)], with: .none)
        tableView.reloadSections(IndexSet(integer: Section.roundsPerTeam.rawValue), with: .none)
    }

    @objc private func passUnlimitedChanged(_ sender: UISwitch) {
        initialSettings.isPassUnlimited = sender.isOn
        Haptics.shared.selection()
        tableView.reloadRows(at: [IndexPath(row: 1, section: Section.pass.rawValue)], with: .none)
    }

    @objc private func passLimitChanged(_ sender: UIStepper) {
        initialSettings.passLimit = Int(sender.value)
        tableView.reloadRows(at: [IndexPath(row: 1, section: Section.pass.rawValue)], with: .none)
    }

    @objc private func roundsPerTeamChanged(_ sender: UIStepper) {
        initialSettings.roundsPerTeam = Int(sender.value)
        tableView.reloadRows(at: [IndexPath(row: 0, section: Section.roundsPerTeam.rawValue)], with: .none)
        tableView.reloadSections(IndexSet(integer: Section.roundsPerTeam.rawValue), with: .none)
    }

    // MARK: - Color picker

    @objc private func colorDotTapped(_ sender: UIButton) {
        let teamIdx = sender.tag - 20_000
        guard teamIdx >= 0, teamIdx < initialSettings.teamCount else { return }
        Haptics.shared.selection()

        let sheet = UIAlertController(title: "Takım Rengi", message: nil, preferredStyle: .actionSheet)
        for color in Palette.teamColors {
            let name = colorName(color)
            let action = UIAlertAction(title: name, style: .default) { [weak self] _ in
                guard let self = self else { return }
                if self.teamColors.indices.contains(teamIdx) {
                    self.teamColors[teamIdx] = color
                }
                self.tableView.reloadRows(at: [IndexPath(row: teamIdx, section: Section.teamNames.rawValue)],
                                          with: .none)
            }
            sheet.addAction(action)
        }
        sheet.addAction(UIAlertAction(title: "İptal", style: .cancel))
        if let pop = sheet.popoverPresentationController {
            pop.sourceView = sender
            pop.sourceRect  = sender.bounds
        }
        present(sheet, animated: true)
    }

    private func colorName(_ color: UIColor) -> String {
        if color == .systemBlue    { return "Mavi" }
        if color == .systemPink    { return "Pembe" }
        if color == .systemGreen   { return "Yeşil" }
        if color == .systemOrange  { return "Turuncu" }
        if color == .systemPurple  { return "Mor" }
        if color == .systemRed     { return "Kırmızı" }
        return "Renk"
    }

    // MARK: - UITextFieldDelegate

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        let idx = textField.tag - 10_000
        guard idx >= 0 else { return }
        let text = textField.text ?? ""
        if initialSettings.teamNames.indices.contains(idx) {
            initialSettings.teamNames[idx] = text
        } else if idx < initialSettings.teamCount {
            while initialSettings.teamNames.count <= idx {
                initialSettings.teamNames.append("")
            }
            initialSettings.teamNames[idx] = text
        }
    }
}
