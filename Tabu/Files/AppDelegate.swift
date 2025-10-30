//
//  AppDelegate.swift
//  Tabu
//
//  Created by MAHMUT AKIN on 12/10/2025.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    // On iOS 13+, window is owned by SceneDelegate. Keep this for iOS 12 and earlier if you support them.
    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // If you still target iOS 12 or earlier, create the window here.
        // On iOS 13+, SceneDelegate will handle window creation.
        if #available(iOS 18.0, *) {
            // Do nothing here; SceneDelegate will set up the window.
        } else {
            let window = UIWindow(frame: UIScreen.main.bounds)
            window.rootViewController = MainMenuViewController()
            self.window = window
            window.makeKeyAndVisible()
        }
        return true
    }

    // MARK: UISceneSession Lifecycle (iOS 13+)

    @available(iOS 13.0, *)
    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let config = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        config.delegateClass = SceneDelegate.self
        return config
    }
}
