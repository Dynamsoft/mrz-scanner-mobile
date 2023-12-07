//
//  BaseNavigationController.swift
//  SakuraPanoramaDemo

import UIKit

class BaseNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        get {self.topViewController?.preferredStatusBarStyle ?? .lightContent}
    }
    
    override var shouldAutorotate: Bool {
        get {self.topViewController?.shouldAutorotate ?? true}
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        get {self.topViewController?.supportedInterfaceOrientations ?? .all}
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        get {self.topViewController?.preferredInterfaceOrientationForPresentation ?? .portrait}
    }

}
