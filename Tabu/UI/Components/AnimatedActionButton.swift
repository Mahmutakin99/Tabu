import UIKit

final class AnimatedActionButton: UIButton {

    private let hapticsEnabled: Bool

    init(title: String,
         systemName: String,
         color: UIColor,
         hapticsEnabled: Bool = true) {
        self.hapticsEnabled = hapticsEnabled
        super.init(frame: .zero)
        configure(title: title, systemName: systemName, color: color)
    }

    required init?(coder: NSCoder) { fatalError() }

    private func configure(title: String, systemName: String, color: UIColor) {
        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.filled()
            config.title = title
            config.image = UIImage(systemName: systemName)
            config.imagePadding = 8
            config.baseBackgroundColor = color
            config.baseForegroundColor = .white
            config.cornerStyle = .large
            config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
            configuration = config
        } else {
            setTitle(title, for: .normal)
            setImage(UIImage(systemName: systemName), for: .normal)
            tintColor = .white
            backgroundColor = color
            setTitleColor(.white, for: .normal)
            titleLabel?.font = UIFont.scaled(.bold, size: 18, relativeTo: .body)
            layer.cornerRadius = Radius.button
            contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
            imageEdgeInsets = UIEdgeInsets(top: 0, left: -6, bottom: 0, right: 6)
        }
        titleLabel?.font = UIFont.scaled(.bold, size: 18, relativeTo: .body)
        titleLabel?.adjustsFontForContentSizeCategory = true

        Shadow.button.apply(to: layer)
        accessibilityLabel = title

        addTarget(self, action: #selector(onTouchDown), for: [.touchDown, .touchDragEnter])
        addTarget(self, action: #selector(onTouchUp),   for: [.touchUpInside, .touchDragExit, .touchCancel])
    }

    @objc private func onTouchDown() {
        UIView.animate(withDuration: 0.08) {
            self.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
            self.layer.shadowRadius  = Shadow.elevated.radius
            self.layer.shadowOffset  = Shadow.elevated.offset
            self.layer.shadowOpacity = Shadow.elevated.opacity
        }
    }

    @objc private func onTouchUp() {
        if hapticsEnabled { Haptics.shared.impact() }
        UIView.animate(withDuration: 0.12) {
            self.transform = .identity
            Shadow.button.apply(to: self.layer)
        }
    }
}
