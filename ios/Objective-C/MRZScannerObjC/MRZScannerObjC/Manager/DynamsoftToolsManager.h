//
//  DynamsoftToolsManager.h
//  HelloWorldObjC
//
//  Created by Dynamsoft's mac on 2022/9/9.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DynamsoftToolsManager : NSObject<NSCopying, NSMutableCopying>

+ (DynamsoftToolsManager *)manager;

/// Font adaptive width.
/// @param string The content of the string
/// @param font The font of the string
/// @param componentHeight The height of the compoent
- (CGFloat)calculateWidthWithText:(NSString *)string font:(UIFont *)font AndComponentheight:(CGFloat)componentHeight;

/// Font adaptive height.
/// @param string The content of the string
/// @param font The font of the string
/// @param componentWidth The width of the compoent
- (CGFloat)calculateHeightWithText:(NSString *)string font:(UIFont *)font AndComponentWidth:(CGFloat)componentWidth;

/// Checks if the string is empty
- (BOOL)stringIsEmptyOrNull:(NSString*)string;

@end

NS_ASSUME_NONNULL_END
