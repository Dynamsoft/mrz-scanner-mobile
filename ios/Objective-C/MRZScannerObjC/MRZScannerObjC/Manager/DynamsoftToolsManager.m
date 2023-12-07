//
//  DynamsoftToolsManager.m
//  HelloWorldObjC
//
//  Created by Dynamsoft's mac on 2022/9/9.
//

#import "DynamsoftToolsManager.h"

@implementation DynamsoftToolsManager

+ (DynamsoftToolsManager *)manager
{
    static DynamsoftToolsManager *toolsManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        toolsManager = [super allocWithZone:NULL];
    });
    return toolsManager;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    return [DynamsoftToolsManager manager];
}

- (id)copyWithZone:(NSZone *)zone
{
    return [DynamsoftToolsManager manager];
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
    return [DynamsoftToolsManager manager];
}

/// Font adaptive width.
/// @param string The content of the string.
/// @param font The font of the string.
/// @param componentHeight The height of the compoent.
- (CGFloat)calculateWidthWithText:(NSString *)string font:(UIFont *)font AndComponentheight:(CGFloat)componentHeight
{
    if ([self stringIsEmptyOrNull:string]) {
        return 0;
    }
    NSDictionary *dic = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
    CGRect frame = [string boundingRectWithSize:CGSizeMake(10000, componentHeight) options:NSStringDrawingUsesLineFragmentOrigin attributes:dic context:nil];
    
    return frame.size.width;
}

/// Font adaptive height.
/// @param string The content of the string.
/// @param font The font of the string.
/// @param componentWidth The width of the compoent.
- (CGFloat)calculateHeightWithText:(NSString *)string font:(UIFont *)font AndComponentWidth:(CGFloat)componentWidth
{
    if ([self stringIsEmptyOrNull:string]) {
        return 0;
    }
    NSDictionary *dic = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
    CGRect frame = [string boundingRectWithSize:CGSizeMake(componentWidth, 10000) options:NSStringDrawingUsesLineFragmentOrigin attributes:dic context:nil];
    return frame.size.height;
}


/// Checks if the string is empty.
- (BOOL)stringIsEmptyOrNull:(NSString*)string
{
    return ![self notEmptyOrNull:string];
}

/// Checks if the string is not empty
- (BOOL)notEmptyOrNull:(NSString*)string
{
    if ([string isKindOfClass:[NSNull class]])
        return NO;
    if ([string isEqual:[NSNull null]] || string==nil) {
        return NO;
    }
    if ([string isKindOfClass:[NSNumber class]]) {
        if (string != nil) {
            return YES;
        }
        return NO;
    }
    else {
        string = [self trimString:string];
        if ( [string isEqualToString:@"null"] || [string isEqualToString:@"(null)"] || [string isEqualToString:@" "]|| [string isEqualToString:@""] || [string isEqualToString:@"<null>"]) {
            return NO;
        }
        if (string != nil && string.length > 0) {
            return YES;
        }
        return NO;
    }
}

/// CropString.
- (NSString*)trimString:(NSString*)str
{
    return [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

@end
