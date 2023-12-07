//
//  BaseNavigationController.m
//  GeneralSettings

#import "BaseNavigationController.h"

@interface BaseNavigationController ()<UINavigationBarDelegate>

@end

@implementation BaseNavigationController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
}

- (BOOL)prefersStatusBarHidden
{
    return self.visibleViewController.prefersStatusBarHidden;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    UIViewController* topVC = self.topViewController;
    return [topVC preferredStatusBarStyle];

}

- (BOOL)shouldAutorotate
{
    UIViewController* topVC = self.topViewController;
    return  [topVC shouldAutorotate];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    UIViewController* topVC = self.topViewController;
    return [topVC supportedInterfaceOrientations];
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    UIViewController* topVC = self.topViewController;
    return [topVC preferredInterfaceOrientationForPresentation];
}


@end
