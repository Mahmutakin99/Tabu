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
    var horizontalSpacing: CGFloat = 8
    var verticalSpacing: CGFloat = 8
    
    func setTags(_ tags: [String]) {
        self.tags = tags
        rebuild()
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
        
        for chip in chips {
            let size = chip.intrinsicContentSize
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
        
        for chip in chips {
            let size = chip.intrinsicContentSize
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
        if let w = window?.windowScene?.screen.bounds.width {
            return w - 40
        }
        return 0
    }
}

