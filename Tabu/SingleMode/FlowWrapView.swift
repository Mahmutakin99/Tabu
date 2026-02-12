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
        self.font = UIFontMetrics(forTextStyle: .subheadline)
            .scaledFont(for: UIFont.systemFont(ofSize: 16, weight: .semibold))
        self.adjustsFontForContentSizeCategory = true
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
    private var tagsSignature: Int = 0
    
    private var cachedLayoutWidthKey: Int = -1
    private var cachedIntrinsicWidthKey: Int = -1
    private var cachedIntrinsicHeight: CGFloat = 0
    private var cachedFrames: [CGRect] = []
    private var cachedSignature: Int = 0
    
    var horizontalSpacing: CGFloat = 8
    var verticalSpacing: CGFloat = 8
    
    func setTags(_ tags: [String]) {
        let sanitizedTags = tags
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
        
        if self.tags == sanitizedTags {
            return
        }
        
        self.tags = sanitizedTags
        tagsSignature = Self.signature(for: sanitizedTags)
        
        // Update tags and reuse existing chips when possible.
        if chips.count == sanitizedTags.count {
            for (idx, text) in sanitizedTags.enumerated() {
                let chip = chips[idx]
                chip.text = text
            }
        } else {
            if chips.count > sanitizedTags.count {
                let extras = chips[sanitizedTags.count...]
                extras.forEach { $0.removeFromSuperview() }
                chips.removeLast(chips.count - sanitizedTags.count)
            }
            if chips.count < sanitizedTags.count {
                let startIndex = chips.count
                let toAdd = sanitizedTags.count - startIndex
                for i in 0..<toAdd {
                    let label = PillLabel(text: sanitizedTags[startIndex + i])
                    addSubview(label)
                    chips.append(label)
                }
            }
            for (idx, text) in sanitizedTags.enumerated() {
                chips[idx].text = text
            }
        }
        
        chipSizes = chips.map { $0.intrinsicContentSize }
        invalidateLayoutCaches()
        setNeedsLayout()
        invalidateIntrinsicContentSize()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        let didFontOrLayoutChange =
            previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory ||
            previousTraitCollection?.layoutDirection != traitCollection.layoutDirection
        
        guard didFontOrLayoutChange else { return }
        chipSizes = chips.map { $0.intrinsicContentSize }
        invalidateLayoutCaches()
        setNeedsLayout()
        invalidateIntrinsicContentSize()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let maxWidth = effectiveMaxWidth()
        guard maxWidth > 0 else { return }
        
        let widthKey = normalizedWidthKey(maxWidth)
        if widthKey != cachedLayoutWidthKey ||
            cachedSignature != tagsSignature ||
            cachedFrames.count != chips.count {
            let result = calculateLayout(maxWidth: maxWidth)
            cachedFrames = result.frames
            cachedIntrinsicHeight = result.height
            cachedLayoutWidthKey = widthKey
            cachedIntrinsicWidthKey = widthKey
            cachedSignature = tagsSignature
        }
        
        for (index, chip) in chips.enumerated() where index < cachedFrames.count {
            chip.frame = cachedFrames[index]
        }
    }
    
    override var intrinsicContentSize: CGSize {
        let maxWidth = effectiveMaxWidth()
        if maxWidth <= 0 {
            return CGSize(width: UIView.noIntrinsicMetric, height: 0)
        }
        let widthKey = normalizedWidthKey(maxWidth)
        if widthKey != cachedIntrinsicWidthKey ||
            cachedSignature != tagsSignature ||
            cachedFrames.count != chips.count {
            let result = calculateLayout(maxWidth: maxWidth)
            cachedFrames = result.frames
            cachedIntrinsicHeight = result.height
            cachedIntrinsicWidthKey = widthKey
            cachedLayoutWidthKey = widthKey
            cachedSignature = tagsSignature
        }
        
        return CGSize(width: maxWidth, height: cachedIntrinsicHeight)
    }
    
    private func effectiveMaxWidth() -> CGFloat {
        if bounds.width > 0 {
            return bounds.width
        }
        // Use context-derived screen size.
        if let screenWidth = window?.windowScene?.screen.bounds.width {
            return screenWidth - 40
        }
        // Fallback: use a reasonable default width when view is not yet in hierarchy
        return 350
    }
    
    private func calculateLayout(maxWidth: CGFloat) -> (frames: [CGRect], height: CGFloat) {
        var frames: [CGRect] = []
        frames.reserveCapacity(chips.count)
        
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        for (index, chip) in chips.enumerated() {
            let size = index < chipSizes.count ? chipSizes[index] : chip.intrinsicContentSize
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + verticalSpacing
                rowHeight = 0
            }
            frames.append(CGRect(x: x, y: y, width: size.width, height: size.height))
            x += size.width + horizontalSpacing
            rowHeight = max(rowHeight, size.height)
        }
        
        return (frames, y + rowHeight)
    }
    
    private func invalidateLayoutCaches() {
        cachedLayoutWidthKey = -1
        cachedIntrinsicWidthKey = -1
        cachedIntrinsicHeight = 0
        cachedFrames.removeAll(keepingCapacity: true)
        cachedSignature = 0
    }
    
    private func normalizedWidthKey(_ width: CGFloat) -> Int {
        Int((width * 10).rounded())
    }
    
    private static func signature(for tags: [String]) -> Int {
        var hasher = Hasher()
        hasher.combine(tags.count)
        tags.forEach { hasher.combine($0) }
        return hasher.finalize()
    }
}
