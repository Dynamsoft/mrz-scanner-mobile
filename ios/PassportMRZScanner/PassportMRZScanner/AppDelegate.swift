
import UIKit
import DynamsoftLicense

@main
class AppDelegate: UIResponder, UIApplicationDelegate, LicenseVerificationListener {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        if #available(iOS 15.0,*) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(red: 43 / 255.0, green: 43 / 255.0, blue: 43 / 255.0, alpha: 1)
            appearance.titleTextAttributes = [
                NSAttributedString.Key.foregroundColor: UIColor.white]
            appearance.backButtonAppearance = UIBarButtonItemAppearance(style: .plain)
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        }
        
        LicenseManager.initLicense("DLS2eyJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSJ9", verificationDelegate:self)
        
        return true
    }

    func onLicenseVerified(_ isSuccess: Bool, error: Error?) {
        if(error != nil)
        {
            if let msg = error?.localizedDescription {
                print("Server license verify failed, error:\(msg)")
            }
        }
    }

}

