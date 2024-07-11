
import Foundation
import UIKit

extension UIDevice {
    
    static func ds_safeDistanceTop() -> CGFloat {
        if #available(iOS 13.0, *) {
            let scene = UIApplication.shared.connectedScenes.first
            guard let windowScene = scene as? UIWindowScene else { return 0 }
            guard let window = windowScene.windows.first else { return 0 }
            return window.safeAreaInsets.top
        } else  {
            guard let window = UIApplication.shared.windows.first else { return 0 }
            return window.safeAreaInsets.top
        }
    }

    static func ds_safeDistanceBottom() -> CGFloat {
        if #available(iOS 13.0, *) {
            let scene = UIApplication.shared.connectedScenes.first
            guard let windowScene = scene as? UIWindowScene else { return 0 }
            guard let window = windowScene.windows.first else { return 0 }
            return window.safeAreaInsets.bottom
        } else {
            guard let window = UIApplication.shared.windows.first else { return 0 }
            return window.safeAreaInsets.bottom
        }
    }

    static func ds_statusBarHeight() -> CGFloat {
        var statusBarHeight: CGFloat = 0
        if #available(iOS 13.0, *) {
            let scene = UIApplication.shared.connectedScenes.first
            guard let windowScene = scene as? UIWindowScene else { return 0 }
            guard let statusBarManager = windowScene.statusBarManager else { return 0 }
            statusBarHeight = statusBarManager.statusBarFrame.height
        } else {
            statusBarHeight = UIApplication.shared.statusBarFrame.height
        }
        return statusBarHeight
    }

    static func ds_statusBarFrame() -> CGRect {
        var statusBarFrame: CGRect = CGRectZero
        if #available(iOS 13.0, *) {
            let scene = UIApplication.shared.connectedScenes.first
            guard let windowScene = scene as? UIWindowScene else { return CGRectZero }
            guard let statusBarManager = windowScene.statusBarManager else { return CGRectZero }
            statusBarFrame = statusBarManager.statusBarFrame
        } else {
            statusBarFrame = UIApplication.shared.statusBarFrame
        }
        return statusBarFrame
    }
    
    static func ds_navigationBarHeight() -> CGFloat {
        return 44.0
    }

    static func ds_navigationFullHeight() -> CGFloat {
        return UIDevice.ds_statusBarHeight() + UIDevice.ds_navigationBarHeight()
    }

    static func ds_tabBarHeight() -> CGFloat {
        return 49.0
    }

    static func ds_tabBarFullHeight() -> CGFloat {
        return UIDevice.ds_tabBarHeight() + UIDevice.ds_safeDistanceBottom()
    }
    
    static var deviceOrientation: UIInterfaceOrientation {
        get {
            if #available(iOS 13.0, *) {
                return UIApplication.shared.windows
                    .first?
                    .windowScene?
                    .interfaceOrientation ?? .portrait

            } else {
                return UIApplication.shared.statusBarOrientation
            }
        }
    }
}
