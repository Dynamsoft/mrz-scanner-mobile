//
//  SceneDelegate.swift
//  ScanMRZ
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    // No storyboard, so the root view controller is built here. It is wrapped in a
    // navigation controller because the scanner and result screens are pushed onto it.
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)
        let rootViewController = ViewController()
        let navigationController = UINavigationController(rootViewController: rootViewController)
        window.rootViewController = navigationController
        self.window = window
        window.makeKeyAndVisible()
    }
}

