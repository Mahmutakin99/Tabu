//
//  FlowWrapView.swift
//  Tabu
//
//  Created by MAHMUT AKIN on 13/10/2025.
//

import UIKit

final class PillLabel: UILabel {
    init(text: String) {
        super.init(frame: .zero)
        self.text = text
        self.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        self.textColor = .label
        self.textAlignment = .center
        self.numberOfLines = 1
        self.layer.cornerRadius = 14
        self.layer.masksToBounds = true
        self.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.9)
        //self.backgroundColor = UIColor.white
        self.layer.borderColor = UIColor.separator.withAlphaComponent(0.5).cgColor
        self.layer.borderWidth = 1
        self.translatesAutoresizingMaskIntoConstraints = false
        self.setContentHuggingPriority(.required, for: .horizontal)
        self.setContentCompressionResistancePriority(.required, for: .horizontal)
        self.layoutMargins = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override var intrinsicContentSize: CGSize {
        let base = super.intrinsicContentSize
        let w = base.width + 20
        let h = base.height + 12
        return CGSize(width: w, height: h)
    }
}

final class FlowWrapView: UIView {
    private var tags: [String] = []
    private var chips: [PillLabel] = []
    private var chipSizes: [CGSize] = []
    var horizontalSpacing: CGFloat = 8
    var verticalSpacing: CGFloat = 8
    
    func setTags(_ tags: [String]) {
        // Update tags and reuse existing chips when possible
        self.tags = tags
        // If counts match, just update texts
        if chips.count == tags.count {
            for (idx, text) in tags.enumerated() {
                let chip = chips[idx]
                chip.text = text
            }
        } else {
            // Remove extras
            if chips.count > tags.count {
                let extras = chips[tags.count...]
                extras.forEach { $0.removeFromSuperview() }
                chips.removeLast(chips.count - tags.count)
            }
            // Add missing
            if chips.count < tags.count {
                let startIndex = chips.count
                let toAdd = tags.count - startIndex
                for i in 0..<toAdd {
                    let label = PillLabel(text: tags[startIndex + i])
                    addSubview(label)
                    chips.append(label)
                }
            }
            // Update texts for all
            for (idx, text) in tags.enumerated() {
                chips[idx].text = text
            }
        }
        // Recompute size cache
        chipSizes = chips.map { $0.intrinsicContentSize }
        setNeedsLayout()
        invalidateIntrinsicContentSize()
    }
    
    private func rebuild() {
        chips.forEach { $0.removeFromSuperview() }
        chips = tags.map { PillLabel(text: $0) }
        chips.forEach { addSubview($0) }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let maxWidth = effectiveMaxWidth()
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        for (index, chip) in chips.enumerated() {
            let size = index < chipSizes.count ? chipSizes[index] : chip.intrinsicContentSize
            if x + size.width > maxWidth {
                x = 0
                y += rowHeight + verticalSpacing
                rowHeight = 0
            }
            chip.frame = CGRect(x: x, y: y, width: size.width, height: size.height)
            x += size.width + horizontalSpacing
            rowHeight = max(rowHeight, size.height)
        }
    }
    
    override var intrinsicContentSize: CGSize {
        let maxWidth = effectiveMaxWidth()
        if maxWidth <= 0 {
            return CGSize(width: UIView.noIntrinsicMetric, height: 0)
        }
        
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        for (index, chip) in chips.enumerated() {
            let size = index < chipSizes.count ? chipSizes[index] : chip.intrinsicContentSize
            if x + size.width > maxWidth {
                x = 0
                y += rowHeight + verticalSpacing
                rowHeight = 0
            }
            x += size.width + horizontalSpacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth, height: y + rowHeight)
    }
    
    private func effectiveMaxWidth() -> CGFloat {
        if bounds.width > 0 {
            return bounds.width
        }
        // Use context-derived screen size (iOS 26+ compatible)
        if let screenWidth = window?.windowScene?.screen.bounds.width {
            return screenWidth - 40
        }
        // Fallback: use a reasonable default width when view is not yet in hierarchy
        return 350
    }
}

