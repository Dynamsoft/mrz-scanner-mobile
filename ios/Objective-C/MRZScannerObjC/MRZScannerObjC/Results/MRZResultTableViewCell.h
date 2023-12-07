//
//  MRZResultTableViewCell.h
//  MRZScannerObjC
//
//  Created by Dynamsoft's mac on 2022/9/14.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MRZResultTableViewCell : UITableViewCell

- (void)updateUIWithString:(NSString *)resultString;

+ (CGFloat)cellHeightWithString:(NSString *)resultString;

@end

NS_ASSUME_NONNULL_END
