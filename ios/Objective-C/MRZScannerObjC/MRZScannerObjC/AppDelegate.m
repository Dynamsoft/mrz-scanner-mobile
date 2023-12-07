//
//  AppDelegate.m
//  MRZScannerObjC

#import "AppDelegate.h"
#import "ViewController.h"

@interface AppDelegate ()<LicenseVerificationListener>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    if(@available(ios 15.0,*)){
        UINavigationBarAppearance *appearance = [UINavigationBarAppearance new];
        [appearance configureWithOpaqueBackground];
        appearance.backgroundColor = [UIColor colorWithRed:59.003/255.0 green:61.9991/255.0 blue:69.0028/255.0 alpha:1];
        appearance.titleTextAttributes = @{NSForegroundColorAttributeName:[UIColor whiteColor]};
        [[UINavigationBar appearance] setStandardAppearance:appearance];
        [[UINavigationBar appearance] setScrollEdgeAppearance:appearance];
    }
    
    ViewController *vc = [[ViewController alloc] init];
    BaseNavigationController *navi = [[BaseNavigationController alloc] initWithRootViewController:vc];
    self.window.rootViewController = navi;
    
    [DynamsoftLicenseManager initLicense:@"DLS2eyJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSJ9" verificationDelegate:self];
    
    return YES;
}

// MARK: - LicenseVerificationListener
- (void)licenseVerificationCallback:(bool)isSuccess error:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString* msg = @"";
        if(error != nil)
        {
            msg = error.userInfo[NSUnderlyingErrorKey];
            if(msg == nil)
            {
                msg = [error localizedDescription];
            }

            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Server license verify failed" message:msg preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * action) {
                                                       
                                                    }]];
            UIViewController *topViewController = self.window.rootViewController;
            [topViewController presentViewController:alert animated:YES completion:nil];
        }
    });
   
}

@end
