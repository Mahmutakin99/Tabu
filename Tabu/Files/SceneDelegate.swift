//
//  SceneDelegate.swift
//  Tabu
//
//  Created by MAHMUT AKIN on 13/10/2025.
//

import UIKit

@available(iOS 13.0, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    // Called when the system creates a new scene (window)
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)

        let main = MainMenuViewController()
        let nav = UINavigationController(rootViewController: main)
        window.rootViewController = nav

        self.window = window
        window.makeKeyAndVisible()
    }

    // Optional: if you need to respond to scene lifecycle events, add them here.
}
