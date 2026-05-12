import UIKit

extension UIAlertController {
    static func makeExitConfirm(handler: @escaping () -> Void) -> UIAlertController {
        let alert = UIAlertController(title: "Oyunu Bitir?",
                                      message: "Süre dolmadan çıkmak istiyor musunuz?",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "İptal", style: .cancel))
        alert.addAction(UIAlertAction(title: "Evet", style: .destructive) { _ in handler() })
        return alert
    }
}
