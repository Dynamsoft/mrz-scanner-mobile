//
//  ViewController.m
//  MRZScannerObjC

#import "ViewController.h"

@interface ViewController ()<MRZResultListener>

@property (nonatomic, strong) DynamsoftMRZRecognizer *mrzRecognizer;

@property (nonatomic, strong) DynamsoftCameraEnhancer *cameraEnhancer;

@property (nonatomic, strong) DCECameraView *dceView;

@property (nonatomic, assign) UIInterfaceOrientation currentInterfaceOrientation;

@property (nonatomic, assign) BOOL isOrientationUseful;

@end

@implementation ViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName:[UIColor whiteColor]};
    [self.navigationController.navigationBar setBarTintColor:[UIColor colorWithRed:59.003/255.0 green:61.9991/255.0 blue:69.0028/255.0 alpha:1]];

    self.isOrientationUseful = YES;
    [self.mrzRecognizer startScanning];
   
    switch (self.currentInterfaceOrientation) {
        case UIInterfaceOrientationPortrait:
            [UIDevice setOrientation:UIInterfaceOrientationPortrait];
            break;
        case UIInterfaceOrientationLandscapeRight:
            [UIDevice setOrientation:UIInterfaceOrientationLandscapeRight];
            break;
        default:
            [UIDevice setOrientation:UIInterfaceOrientationPortrait];
            break;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.isOrientationUseful = NO;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"MRZ Scanner";
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChange) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    
    self.currentInterfaceOrientation = UIInterfaceOrientationPortrait;
    self.isOrientationUseful = YES;
    
    [self configureMRZ];
}

- (void)configureMRZ {
    self.mrzRecognizer = [[DynamsoftMRZRecognizer alloc] init];
    
    self.dceView = [[DCECameraView alloc] initWithFrame:self.view.bounds];
    self.cameraEnhancer = [[DynamsoftCameraEnhancer alloc] initWithView:self.dceView];
    [self.view addSubview:self.dceView];
    [self.cameraEnhancer open];
    
    [self.mrzRecognizer setImageSource:self.cameraEnhancer];
    [self.mrzRecognizer setMRZResultListener:self];
    [self.mrzRecognizer startScanning];
    
    iRegionDefinition *region = [[iRegionDefinition alloc] init];
    region.regionLeft = 5;
    region.regionRight = 95;
    region.regionTop = 40;
    region.regionBottom = 60;
    region.regionMeasuredByPercentage = 1;
    [self.cameraEnhancer setScanRegion:region error:nil];

}

- (void)mrzResultCallback:(NSInteger)frameId imageData:(iImageData *)imageData result:(iMRZResult *)result {
    if (result != nil) {
        [self.mrzRecognizer stopScanning];
        if (self.isOrientationUseful) {
            MRZResultViewController *mrzResultVC = [[MRZResultViewController alloc] init];
            mrzResultVC.mrzResult = result;
            [self.navigationController pushViewController:mrzResultVC animated:YES];
        }
    }
}

// MARK: - Orientation

- (void)orientationChange {
    if (self.isOrientationUseful != YES) {
        return;
    }

    self.currentInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscapeRight;
}

- (BOOL)shouldAutorotate {
    return YES;
}

@end
