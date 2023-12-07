//
//  MRZResultTableViewCell.m
//  MRZScannerObjC
//
//  Created by Dynamsoft's mac on 2022/9/14.
//

#import "MRZResultTableViewCell.h"

@interface MRZResultTableViewCell ()

@property (nonatomic, strong) UILabel *resultLabel;

@end

@implementation MRZResultTableViewCell

+ (CGFloat)cellHeightWithString:(NSString *)resultString {
    return [[DynamsoftToolsManager manager] calculateHeightWithText:resultString font:[UIFont systemFontOfSize:KMRZResultTextFont] AndComponentWidth:KMRZResultTextWidth] + 10;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.backgroundColor = [UIColor whiteColor];
    
    [self addSubview:self.resultLabel];
}

- (void)updateUIWithString:(NSString *)resultString {
    self.resultLabel.text = resultString;
    self.resultLabel.height = [[DynamsoftToolsManager manager] calculateHeightWithText:resultString font:[UIFont systemFontOfSize:KMRZResultTextFont] AndComponentWidth:KMRZResultTextWidth];
}

// MARK: - Lazy
- (UILabel *)resultLabel {
    if (!_resultLabel) {
        _resultLabel = [[UILabel alloc] initWithFrame:CGRectMake(kComponentLeftMargin, 0, KMRZResultTextWidth, 0)];
        _resultLabel.textColor = [UIColor blackColor];
        _resultLabel.font = [UIFont systemFontOfSize:KMRZResultTextFont];
        _resultLabel.numberOfLines = 0;
    }
    return _resultLabel;
}


@end
