
import Foundation
import UIKit

let kScreenWidth = UIScreen.main.bounds.size.width

let kScreenHeight = UIScreen.main.bounds.size.height

let kNavigationBarFullHeight = UIDevice.ds_navigationFullHeight()

let kTabBarSafeAreaHeight = UIDevice.ds_safeDistanceBottom()

typealias ConfirmCompletion = () -> Void

let parseFailedTip = "Failed to parse the result.\n The MRZ text is :\n"
