import UIKit

final class GradientBackgroundView: UIView {
    private let gradient = CAGradientLayer()
    private var colors: [UIColor]

    init(colors: [UIColor] = Palette.gameGradientColors) {
        self.colors = colors
        super.init(frame: .zero)
        gradient.colors = colors.map(\.cgColor)
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint   = CGPoint(x: 1, y: 1)
        layer.insertSublayer(gradient, at: 0)
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradient.frame = bounds
        CATransaction.commit()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }
        gradient.colors = colors.map(\.cgColor)
    }

    func updateColors(_ newColors: [UIColor]) {
        colors = newColors
        gradient.colors = newColors.map(\.cgColor)
    }
}
