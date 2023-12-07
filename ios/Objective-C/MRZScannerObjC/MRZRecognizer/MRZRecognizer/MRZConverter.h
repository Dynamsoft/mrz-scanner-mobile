//
//  MRZConverter.h
//  DynamsoftMRZRecognizer

#import <Foundation/Foundation.h>
#import "DynamsoftMRZRecognizer.h"

NS_ASSUME_NONNULL_BEGIN

@interface MRZConverter : NSObject

+ (nullable iMRZResult *)getMRZResultWith:(NSArray<NSString *> *)dlrLineTextResultsArray;

@end

NS_ASSUME_NONNULL_END
