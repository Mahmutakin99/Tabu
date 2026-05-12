import UIKit

final class Haptics {
    static let shared = Haptics()

    private let notif  = UINotificationFeedbackGenerator()
    private let light  = UIImpactFeedbackGenerator(style: .light)
    private let medium = UIImpactFeedbackGenerator(style: .medium)
    private let heavy  = UIImpactFeedbackGenerator(style: .heavy)
    private let sel    = UISelectionFeedbackGenerator()

    private init() {
        notif.prepare()
        medium.prepare()
        sel.prepare()
    }

    func success()   { notif.notificationOccurred(.success);  notif.prepare() }
    func warning()   { notif.notificationOccurred(.warning);  notif.prepare() }
    func error()     { notif.notificationOccurred(.error);    notif.prepare() }
    func selection() { sel.selectionChanged();                sel.prepare()   }

    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        switch style {
        case .light:  light.impactOccurred();  light.prepare()
        case .heavy:  heavy.impactOccurred();  heavy.prepare()
        default:      medium.impactOccurred(); medium.prepare()
        }
    }
}
