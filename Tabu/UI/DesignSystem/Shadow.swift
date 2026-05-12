import UIKit

struct ShadowStyle {
    let color: UIColor
    let opacity: Float
    let radius: CGFloat
    let offset: CGSize

    func apply(to layer: CALayer) {
        layer.shadowColor   = color.cgColor
        layer.shadowOpacity = opacity
        layer.shadowRadius  = radius
        layer.shadowOffset  = offset
    }
}

enum Shadow {
    static let card     = ShadowStyle(color: .black, opacity: 0.22, radius: 14, offset: CGSize(width: 0, height: 6))
    static let button   = ShadowStyle(color: .black, opacity: 0.25, radius:  8, offset: CGSize(width: 0, height: 4))
    static let elevated = ShadowStyle(color: .black, opacity: 0.18, radius:  6, offset: CGSize(width: 0, height: 3))
}
