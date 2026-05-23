import UIKit

// Snapshot tabanlı cross-dissolve kart geçişi.
// Önceki snapshot in-flight iken yeni tap gelirse: eski snapshot temizlenir,
// yeni snapshot yerleştirilir. removeAllAnimations() çağrılmaz → snap yok.
final class CardSwipeAnimator {
    private weak var cardView: UIView?
    private var flyingSnapshot: UIView?

    private enum Timing {
        static let glow: TimeInterval = 0.24
        static let exit: TimeInterval = 0.68
        static let entry: TimeInterval = 0.52
        static let entryDelay: TimeInterval = 0.14
    }

    init(cardView: UIView) {
        self.cardView = cardView
    }

    enum Direction { case left, right }

    func swipe(direction: Direction,
               contentUpdate: @escaping () -> Void,
               completion: (() -> Void)? = nil) {
        guard let card = cardView else { return }

        // Eğer önceki bir snapshot uçuşta ise kaldır.
        flyingSnapshot?.removeFromSuperview()
        flyingSnapshot = nil

        // Mevcut kartın anlık görüntüsünü al.
        let snapshot = card.snapshotView(afterScreenUpdates: false) ?? UIView()
        snapshot.frame = card.frame
        snapshot.layer.cornerRadius = card.layer.cornerRadius
        snapshot.clipsToBounds = true
        card.superview?.insertSubview(snapshot, aboveSubview: card)
        flyingSnapshot = snapshot

        // Kart içeriğini hemen güncelle (kullanıcı görmüyor, snapshot örtüyor).
        contentUpdate()

        // Kartı geri "kaydedilmiş" pozisyonda göster ama zaten yerinde.
        // Snapshot'u uçur.
        let xSign: CGFloat = direction == .right ? 1 : -1
        let angle: CGFloat  = xSign * (.pi / 14)

        let glow = CABasicAnimation(keyPath: "opacity")
        glow.fromValue = 0.0
        glow.toValue   = 1.0
        glow.duration  = Timing.glow
        glow.autoreverses = true
        card.layer.sublayers?
            .compactMap { $0 as? CAGradientLayer }
            .last?
            .add(glow, forKey: "glow")

        UIView.animate(withDuration: Timing.exit, delay: 0,
                       usingSpringWithDamping: 0.92, initialSpringVelocity: 0) {
            snapshot.transform = CGAffineTransform(rotationAngle: angle)
                .translatedBy(x: xSign * UIScreen.main.bounds.width, y: -30)
            snapshot.alpha = 0
        } completion: { [weak self] _ in
            snapshot.removeFromSuperview()
            if self?.flyingSnapshot === snapshot { self?.flyingSnapshot = nil }
            completion?()
        }

        // Yeni içeriğin karta scale-in + fade-in girişi
        card.alpha = 0
        card.transform = CGAffineTransform(scaleX: 0.88, y: 0.88)
        UIView.animate(withDuration: Timing.entry, delay: Timing.entryDelay,
                       usingSpringWithDamping: 0.68, initialSpringVelocity: 0.4) {
            card.alpha = 1
            card.transform = .identity
        }
    }
}
