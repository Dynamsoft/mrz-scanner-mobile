//
//  SceneDelegate.swift
//  ScanMRZBasic
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    // The sample has no storyboard, so the one and only view controller becomes the
    // root here. The scanner is presented on top of it rather than pushed, which is
    // why there is no navigation controller either.
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = ViewController()
        self.window = window
        window.makeKeyAndVisible()
    }
}
