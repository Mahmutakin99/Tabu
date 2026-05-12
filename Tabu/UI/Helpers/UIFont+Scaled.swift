import UIKit

extension UIFont {
    static func scaled(_ weight: UIFont.Weight,
                       size: CGFloat,
                       relativeTo style: UIFont.TextStyle) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        return UIFontMetrics(forTextStyle: style).scaledFont(for: base)
    }

    static func scaledMonospaced(size: CGFloat,
                                  weight: UIFont.Weight,
                                  relativeTo style: UIFont.TextStyle) -> UIFont {
        let base = UIFont.monospacedDigitSystemFont(ofSize: size, weight: weight)
        return UIFontMetrics(forTextStyle: style).scaledFont(for: base)
    }
}
