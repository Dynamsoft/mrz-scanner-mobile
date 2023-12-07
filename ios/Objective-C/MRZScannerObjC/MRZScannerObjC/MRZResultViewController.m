//
//  MRZResultViewController.m
//  MRZScannerObjC

#import "MRZResultViewController.h"

@interface MRZResultViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *mrzResultTableView;

@property (nonatomic, strong) NSMutableArray *mrzDataArray;

@end

@implementation MRZResultViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [UIDevice setOrientation:UIInterfaceOrientationPortrait];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"MRZ Result";
    
    [self createData];
    [self setupUI];
}

- (void)setupUI {
    [self.view addSubview:self.mrzResultTableView];
}

- (void)createData {
    self.mrzDataArray = [NSMutableArray array];
    [self.mrzDataArray addObject:@{@"RowPrefix":@"Document Type",
                                   @"Content":(self.mrzResult.docType == nil || self.mrzResult.docType.length == 0) ? @"nil":self.mrzResult.docType
                                 }];
    [self.mrzDataArray addObject:@{@"RowPrefix":@"Issuing State",
                                   @"Content":(self.mrzResult.issuer == nil || self.mrzResult.issuer.length == 0) ? @"nil":self.mrzResult.issuer
                                 }];
    [self.mrzDataArray addObject:@{@"RowPrefix":@"Surname",
                                   @"Content":(self.mrzResult.surname == nil || self.mrzResult.surname.length == 0) ? @"nil":self.mrzResult.surname
                                 }];
    [self.mrzDataArray addObject:@{@"RowPrefix":@"Given Name",
                                   @"Content":(self.mrzResult.givenName == nil || self.mrzResult.givenName.length == 0) ? @"nil":self.mrzResult.givenName
                                 }];
    [self.mrzDataArray addObject:@{@"RowPrefix":@"ID",
                                   @"Content":(self.mrzResult.docId == nil || self.mrzResult.docId.length == 0)? @"nil":self.mrzResult.docId
                                 }];
    [self.mrzDataArray addObject:@{@"RowPrefix":@"Nationality",
                                   @"Content":(self.mrzResult.nationality == nil || self.mrzResult.nationality.length == 0) ? @"nil":self.mrzResult.nationality
                                 }];
    [self.mrzDataArray addObject:@{@"RowPrefix":@"Date of Birth(YYYY-MM-DD)",
                                   @"Content":(self.mrzResult.dateOfBirth == nil || self.mrzResult.dateOfBirth.length == 0) ? @"nil":self.mrzResult.dateOfBirth
                                 }];
    [self.mrzDataArray addObject:@{@"RowPrefix":@"Gender",
                                   @"Content":(self.mrzResult.gender == nil || self.mrzResult.gender.length == 0) ? @"nil":self.mrzResult.gender
                                 }];
    [self.mrzDataArray addObject:@{@"RowPrefix":@"Date of Expiry(YYYY-MM-DD)",
                                   @"Content":(self.mrzResult.dateOfExpiration == nil || self.mrzResult.dateOfExpiration.length == 0)? @"nil":self.mrzResult.dateOfExpiration
                                 }];
    [self.mrzDataArray addObject:@{@"RowPrefix":@"IsParsed",
                                   @"Content":self.mrzResult.isParsed?@"YES":@"NO"
                                 }];
    [self.mrzDataArray addObject:@{@"RowPrefix":@"IsVerified",
                                   @"Content":self.mrzResult.isVerified?@"YES":@"NO"
                                 }];
    [self.mrzDataArray addObject:@{@"RowPrefix":@"MRZ String",
                                   @"Content":[NSString stringWithFormat:@"\n%@", (self.mrzResult.mrzText == nil || self.mrzResult.mrzText.length == 0) ? @"nil":self.mrzResult.mrzText]
                                 }];
}



- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.mrzDataArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *mrzLineDic = self.mrzDataArray[indexPath.row];
    NSString *mrzLineText = [NSString stringWithFormat:@"%@:%@", [mrzLineDic valueForKey:@"RowPrefix"], [mrzLineDic valueForKey:@"Content"]];
    return [MRZResultTableViewCell cellHeightWithString:mrzLineText];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"MRZResultCell";
    MRZResultTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[MRZResultTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    NSDictionary *mrzLineDic = self.mrzDataArray[indexPath.row];
    NSString *mrzLineText = [NSString stringWithFormat:@"%@:%@", [mrzLineDic valueForKey:@"RowPrefix"], [mrzLineDic valueForKey:@"Content"]];
    [cell updateUIWithString:mrzLineText];
    return cell;
}

// MARK: - Orientation
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotate {
    return YES;
}

// MARK: - Lazy
- (UITableView *)mrzResultTableView {
    if (!_mrzResultTableView) {
        _mrzResultTableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _mrzResultTableView.backgroundColor = [UIColor clearColor];
        _mrzResultTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _mrzResultTableView.delegate = self;
        _mrzResultTableView.dataSource = self;
    }
    return _mrzResultTableView;
}

@end
