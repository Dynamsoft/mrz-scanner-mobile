//
//  MRZConverter.m
//  DynamsoftMRZRecognizer

#import "MRZConverter.h"

// TD1(Identity), length is 30.
static NSString *const ID_TD1_LINE1_REGEX = @"^[ACI][A-Z<]([A-Z<]{3})([A-Z0-9<]{9})[0-9][A-Z0-9<]{15}$";
static NSString *const ID_TD1_LINE2_REGEX = @"^(([0-9]{2})(0[0-9]|1[0-2])(0[1-9]|[1-2][0-9]|3[0-1]))[0-9]([MF<])(([0-9]{2})(0[0-9]|1[0-2])(0[1-9]|[1-2][0-9]|3[0-1]))[0-9]([A-Z<]{3})[A-Z0-9<]{11}[0-9]$";
static NSString *const ID_TD1_LINE3_REGEX = @"^([A-Z<]*)$";

// TD2(Identity | MRVB), length is 36.

// Identity
static NSString *const ID_TD2_LINE1_REGEX = @"^[ACI][A-Z<]([A-Z<]{3})([A-Z<]*)$";
static NSString *const ID_TD2_LINE2_REGEX = @"^([A-Z0-9<]{9})[0-9]([A-Z<]{3})(([0-9]{2})(0[0-9]|1[0-2])(0[1-9]|[1-2][0-9]|3[0-1]))[0-9]([MF<])(([0-9]{2})(0[0-9]|1[0-2])(0[1-9]|[1-2][0-9]|3[0-1]))[0-9][A-Z0-9<]{7}[0-9]$";

// MRVB.
static NSString *const MRVB_LINE1_REGEX = @"^V[A-Z<]([A-Z<]{3})([A-Z<]*)$";
static NSString *const MRVB_LINE2_REGEX = @"^([A-Z0-9<]{9})[0-9]([A-Z<]{3})(([0-9]{2})(0[0-9]|1[0-2])(0[1-9]|[1-2][0-9]|3[0-1]))[0-9]([MF<])(([0-9]{2})(0[0-9]|1[0-2])(0[1-9]|[1-2][0-9]|3[0-1]))[0-9][A-Z0-9<]{8}$";

// TD3(Passport | MRVA), length is 44.

// Passport.
static NSString *const PASSPORT_LINE1_REGEX = @"^P[A-Z<]([A-Z<]{3})([A-Z<]*)$";
static NSString *const PASSPORT_LINE2_REGEX = @"^([A-Z0-9<]{9})[0-9]([A-Z<]{3})(([0-9]{2})(0[0-9]|1[0-2])(0[1-9]|[1-2][0-9]|3[0-1]))[0-9]([MF<])(([0-9]{2})(0[0-9]|1[0-2])(0[1-9]|[1-2][0-9]|3[0-1]))[0-9]([A-Z0-9<]{14})[0-9<][0-9]$";

// MRVA.
static NSString *const MRVA_LINE1_REGEX = @"^V[A-Z<]([A-Z<]{3})([A-Z<]*)$";
static NSString *const MRVA_LINE2_REGEX = @"^([A-Z0-9<]{9})[0-9]([A-Z<]{3})(([0-9]{2})(0[0-9]|1[0-2])(0[1-9]|[1-2][0-9]|3[0-1]))[0-9]([MF<])(([0-9]{2})(0[0-9]|1[0-2])(0[1-9]|[1-2][0-9]|3[0-1]))[0-9][A-Z0-9<]{16}$";


@implementation MRZConverter

+ (iMRZResult *)getMRZResultWith:(NSArray<NSString *> *)dlrLineTextResultsArray {
    // Third.
    NSMutableArray *dlrLineTextArr = [NSMutableArray array];
    for (NSString *lineText in dlrLineTextResultsArray) {
        if (lineText.length == 30 || lineText.length == 36 || lineText.length == 44) {
            [dlrLineTextArr addObject:lineText];
        }
    }
    
    NSMutableArray *dlrSuitableTextArr = [NSMutableArray array];
    NSInteger lineStrLength = 0;
    BOOL isFirstMatch = YES;
    BOOL isSuitableForMRZ = YES;
    for (NSString *lineText in dlrLineTextArr) {
        if (isFirstMatch == YES) {
            isFirstMatch = NO;
            lineStrLength = lineText.length;
            [dlrSuitableTextArr addObject:lineText];
            continue;
        } else {
            if (lineText.length == lineStrLength) {
                [dlrSuitableTextArr addObject:lineText];
                continue;
            } else {
                isSuitableForMRZ = NO;
                break;
            }
        }
    }
    
    if (isSuitableForMRZ) {
        iMRZResult *mrzResult = nil;
        NSArray *matchedDLRArr = nil;
        if (lineStrLength == 30 && dlrSuitableTextArr.count >= 3) {
            matchedDLRArr = [dlrSuitableTextArr subarrayWithRange:NSMakeRange(dlrSuitableTextArr.count - 3, 3)];
            mrzResult = [self getTD1ResultWith:matchedDLRArr];
            if (mrzResult.isParsed) {
                return mrzResult;
            } else {
                return [self getTD1ResultWith:[matchedDLRArr reverseObjectEnumerator].allObjects];
            }
        } else if (lineStrLength == 36 && dlrSuitableTextArr.count >= 2) {
            matchedDLRArr = [dlrSuitableTextArr subarrayWithRange:NSMakeRange(dlrSuitableTextArr.count - 2, 2)];
            mrzResult = [self getTD2ResultWith:matchedDLRArr];
            if (mrzResult.isParsed) {
                return mrzResult;
            } else {
                mrzResult = [self getTD2ResultWith:[matchedDLRArr reverseObjectEnumerator].allObjects];
                if (mrzResult.isParsed) {
                    return mrzResult;
                } else {// Use MRVB.
                    mrzResult = [self getMRVBResultWith:matchedDLRArr];
                    if (mrzResult.isParsed) {
                        return mrzResult;
                    } else {
                        return [self getMRVBResultWith:[matchedDLRArr reverseObjectEnumerator].allObjects];;
                    }
                }
            }
        } else if (lineStrLength == 44 && dlrSuitableTextArr.count >= 2) {
            matchedDLRArr = [dlrSuitableTextArr subarrayWithRange:NSMakeRange(dlrSuitableTextArr.count - 2, 2)];
            mrzResult = [self getTD3ResultWith:matchedDLRArr];
            if (mrzResult.isParsed) {
                return mrzResult;
            } else {
                mrzResult = [self getTD3ResultWith:[matchedDLRArr reverseObjectEnumerator].allObjects];
                if (mrzResult.isParsed) {
                    return mrzResult;
                } else {// Use MRVA.
                    mrzResult = [self getMRVAResultWith:matchedDLRArr];
                    if (mrzResult.isParsed) {
                        return mrzResult;
                    } else {
                        return [self getMRVAResultWith:[matchedDLRArr reverseObjectEnumerator].allObjects];
                    }
                }
                
            }
        }
    }
    return nil;
}

+ (nullable iMRZResult *)getTD1ResultWith:(NSArray<NSString *> *)dlrLineTextResultsArray {
    iMRZResult *mrzResult = [[iMRZResult alloc] init];
    mrzResult.isParsed = YES;

    // MRZText.
    NSMutableString *mrzText = [NSMutableString string];
    [mrzText appendString:dlrLineTextResultsArray[0]];
    [mrzText appendString:@"\n"];
    [mrzText appendString:dlrLineTextResultsArray[1]];
    [mrzText appendString:@"\n"];
    [mrzText appendString:dlrLineTextResultsArray[2]];
    mrzResult.mrzText = mrzText;
    
    
    NSArray *line1MatchedArray = [self matchString:dlrLineTextResultsArray[0] regexString:ID_TD1_LINE1_REGEX];
    NSArray *line2MatchedArray = [self matchString:dlrLineTextResultsArray[1] regexString:ID_TD1_LINE2_REGEX];
    NSArray *line3MatchedArray = [self matchString:dlrLineTextResultsArray[2] regexString:ID_TD1_LINE3_REGEX];
    if (line1MatchedArray.count == 0 || line2MatchedArray.count == 0 || line3MatchedArray == 0) {
        mrzResult.isParsed = NO;
        return mrzResult;
    }
    mrzResult.isVerified = YES;
    mrzResult.docType = @"identity";
   
    // Line1.
    if (line1MatchedArray.count != 0) {
        mrzResult.issuer = [line1MatchedArray[1] stringByReplacingOccurrencesOfString:@"<" withString:@""];
        mrzResult.docId = [line1MatchedArray[2] stringByReplacingOccurrencesOfString:@"<" withString:@""];
        if (![self verifyString:line1MatchedArray[2] specifyChar:[dlrLineTextResultsArray[0] characterAtIndex:14]]) {// Check digital of document number
            mrzResult.isVerified = NO;
        }
    }
    
    // Line2.
    if (line2MatchedArray.count != 0) {
        // Birth date.
        NSMutableString *dateOfBirth = [NSMutableString string];
        [dateOfBirth appendString:line2MatchedArray[2]];
        [dateOfBirth appendString:@"-"];
        [dateOfBirth appendString:line2MatchedArray[3]];
        [dateOfBirth appendString:@"-"];
        [dateOfBirth appendString:line2MatchedArray[4]];
        
        mrzResult.dateOfBirth = dateOfBirth;
        
        if (![self verifyString:line2MatchedArray[1] specifyChar:[dlrLineTextResultsArray[1] characterAtIndex:6]]) {// Check digital of birth date
            mrzResult.isVerified = NO;
        }
        
        // Gender.
        mrzResult.gender = [line2MatchedArray[5] stringByReplacingOccurrencesOfString:@"<" withString:@"U"];
        
        // Date of expiration.
        NSMutableString *dateOfExpiration = [NSMutableString string];
        [dateOfExpiration appendString:line2MatchedArray[7]];
        [dateOfExpiration appendString:@"-"];
        [dateOfExpiration appendString:line2MatchedArray[8]];
        [dateOfExpiration appendString:@"-"];
        [dateOfExpiration appendString:line2MatchedArray[9]];
        
        mrzResult.dateOfExpiration = dateOfExpiration;
        
        if (![self verifyString:line2MatchedArray[6] specifyChar:[dlrLineTextResultsArray[1] characterAtIndex:14]]) {// check digital of expiration date
            mrzResult.isVerified = NO;
        }
        
        // Nationality.
        mrzResult.nationality = [line2MatchedArray[10] stringByReplacingOccurrencesOfString:@"<" withString:@""];
        
        // Check all.
        NSMutableString *checkAllStr = [NSMutableString string];
        [checkAllStr appendString:[dlrLineTextResultsArray[0] substringFromIndex:5]];
        [checkAllStr appendString:[dlrLineTextResultsArray[1] substringWithRange:NSMakeRange(0, 7 - 0)]];
        [checkAllStr appendString:[dlrLineTextResultsArray[1] substringWithRange:NSMakeRange(8, 15 - 8)]];
        [checkAllStr appendString:[dlrLineTextResultsArray[1] substringWithRange:NSMakeRange(18, 29 - 18)]];
        
        if (![self verifyString:checkAllStr specifyChar:[dlrLineTextResultsArray[1] characterAtIndex:29]]) {// check digital of all
            mrzResult.isVerified = NO;
        }
    }
    
    // Line3.
    if (line3MatchedArray.count != 0) {
        NSString* name = dlrLineTextResultsArray[2];
        NSRange range = [name rangeOfString:@"<<"];
        if (range.location == NSNotFound) {
            mrzResult.surname = @"";
            mrzResult.givenName = [name stringByReplacingOccurrencesOfString:@"<" withString:@" "];
        } else {
            mrzResult.surname = [[name substringToIndex:range.location] stringByReplacingOccurrencesOfString:@"<" withString:@" "];
            mrzResult.givenName = [[name substringFromIndex:range.location + range.length] stringByReplacingOccurrencesOfString:@"<" withString:@" "];
            if ([mrzResult.givenName stringByReplacingOccurrencesOfString:@" " withString:@""].length == 0) {
                mrzResult.givenName = mrzResult.surname;
                mrzResult.surname = @"";
            }
        }
    }

    return mrzResult;
}

+ (nullable iMRZResult *)getTD2ResultWith:(NSArray<NSString *> *)dlrLineTextResultsArray {
    iMRZResult *mrzResult = [[iMRZResult alloc] init];
    mrzResult.isParsed = YES;
    
    // MRZText.
    NSMutableString *mrzText = [NSMutableString string];
    [mrzText appendString:dlrLineTextResultsArray[0]];
    [mrzText appendString:@"\n"];
    [mrzText appendString:dlrLineTextResultsArray[1]];
    mrzResult.mrzText = mrzText;
    
    NSArray *line1MatchedArray = [self matchString:dlrLineTextResultsArray[0] regexString:ID_TD2_LINE1_REGEX];
    NSArray *line2MatchedArray = [self matchString:dlrLineTextResultsArray[1] regexString:ID_TD2_LINE2_REGEX];
    
    if (line1MatchedArray.count == 0 || line2MatchedArray.count == 0) {
        mrzResult.isParsed = NO;
        return mrzResult;
    }
    
    mrzResult.docType = @"identity";
    mrzResult.isVerified = YES;
    
    // Line1.
    if (line1MatchedArray.count != 0) {
        mrzResult.issuer = [line1MatchedArray[1] stringByReplacingOccurrencesOfString:@"<" withString:@""];

        NSString* name = line1MatchedArray[2];
        NSRange range = [name rangeOfString:@"<<"];
        if (range.location == NSNotFound) {
            mrzResult.surname = @"";
            mrzResult.givenName = [name stringByReplacingOccurrencesOfString:@"<" withString:@" "];
        } else {
            mrzResult.surname = [[name substringToIndex:range.location] stringByReplacingOccurrencesOfString:@"<" withString:@" "];
            mrzResult.givenName = [[name substringFromIndex:range.location + range.length] stringByReplacingOccurrencesOfString:@"<" withString:@" "];
            if ([mrzResult.givenName stringByReplacingOccurrencesOfString:@" " withString:@""].length == 0) {
                mrzResult.givenName = mrzResult.surname;
                mrzResult.surname = @"";
            }
        }
    }
    
    // Line2.
    if (line2MatchedArray.count != 0) {
        // DocId.
        mrzResult.docId = [line2MatchedArray[1] stringByReplacingOccurrencesOfString:@"<" withString:@""];
        if (![self verifyString:line2MatchedArray[1] specifyChar:[dlrLineTextResultsArray[1] characterAtIndex:9]]) {// Check digital of document number
            mrzResult.isVerified = NO;
        }
        
        // Nationality.
        mrzResult.nationality = [line2MatchedArray[2] stringByReplacingOccurrencesOfString:@"<" withString:@""];
        
        // Birth date.
        NSMutableString *dateOfBirth = [NSMutableString string];
        [dateOfBirth appendString:line2MatchedArray[4]];
        [dateOfBirth appendString:@"-"];
        [dateOfBirth appendString:line2MatchedArray[5]];
        [dateOfBirth appendString:@"-"];
        [dateOfBirth appendString:line2MatchedArray[6]];
        
        mrzResult.dateOfBirth = dateOfBirth;
        
        if (![self verifyString:line2MatchedArray[3] specifyChar:[dlrLineTextResultsArray[1] characterAtIndex:19]]) {// Check digital of birth date
            mrzResult.isVerified = NO;
        }
        
        // Gender.
        mrzResult.gender = [line2MatchedArray[7] stringByReplacingOccurrencesOfString:@"<" withString:@"U"];
        
        // Date of expiration.
        NSMutableString *dateOfExpiration = [NSMutableString string];
        [dateOfExpiration appendString:line2MatchedArray[9]];
        [dateOfExpiration appendString:@"-"];
        [dateOfExpiration appendString:line2MatchedArray[10]];
        [dateOfExpiration appendString:@"-"];
        [dateOfExpiration appendString:line2MatchedArray[11]];
        
        mrzResult.dateOfExpiration = dateOfExpiration;
        
        if (![self verifyString:line2MatchedArray[8] specifyChar:[dlrLineTextResultsArray[1] characterAtIndex:27]]) {// check digital of expiration date
            mrzResult.isVerified = NO;
        }
        
        // Check all.
        NSMutableString *checkAllStr = [NSMutableString string];
        [checkAllStr appendString:[dlrLineTextResultsArray[1] substringWithRange:NSMakeRange(0, 10 - 0)]];
        [checkAllStr appendString:[dlrLineTextResultsArray[1] substringWithRange:NSMakeRange(13, 20 - 13)]];
        [checkAllStr appendString:[dlrLineTextResultsArray[1] substringWithRange:NSMakeRange(21, 35 - 21)]];
        
        if (![self verifyString:checkAllStr specifyChar:[dlrLineTextResultsArray[1] characterAtIndex:35]]) {// check digital of all
            mrzResult.isVerified = NO;
        }
    }

    return mrzResult;
}

+ (nullable iMRZResult *)getTD3ResultWith:(NSArray<NSString *> *)dlrLineTextResultsArray {
    iMRZResult *mrzResult = [[iMRZResult alloc] init];
    mrzResult.isParsed = YES;
    
    // MRZText.
    NSMutableString *mrzText = [NSMutableString string];
    [mrzText appendString:dlrLineTextResultsArray[0]];
    [mrzText appendString:@"\n"];
    [mrzText appendString:dlrLineTextResultsArray[1]];
    mrzResult.mrzText = mrzText;
        
    
    NSArray *line1MatchedArray = [self matchString:dlrLineTextResultsArray[0] regexString:PASSPORT_LINE1_REGEX];
    NSArray *line2MatchedArray = [self matchString:dlrLineTextResultsArray[1] regexString:PASSPORT_LINE2_REGEX];
    if (line1MatchedArray.count == 0 || line2MatchedArray.count == 0) {
        mrzResult.isParsed = NO;
        return mrzResult;
    }
    
    mrzResult.docType = @"passport";
    mrzResult.isVerified = YES;
    
    // Line1.
    if (line1MatchedArray.count != 0) {
        mrzResult.issuer = [line1MatchedArray[1] stringByReplacingOccurrencesOfString:@"<" withString:@""];

        NSString* name = line1MatchedArray[2];
        NSRange range = [name rangeOfString:@"<<"];
        if (range.location == NSNotFound) {
            mrzResult.surname = @"";
            mrzResult.givenName = [name stringByReplacingOccurrencesOfString:@"<" withString:@" "];
        } else {
            mrzResult.surname = [[name substringToIndex:range.location] stringByReplacingOccurrencesOfString:@"<" withString:@" "];
            mrzResult.givenName = [[name substringFromIndex:range.location + range.length] stringByReplacingOccurrencesOfString:@"<" withString:@" "];
            if ([mrzResult.givenName stringByReplacingOccurrencesOfString:@" " withString:@""].length == 0) {
                mrzResult.givenName = mrzResult.surname;
                mrzResult.surname = @"";
            }
        }        
    }
    
    // Line2.
    if (line2MatchedArray.count != 0) {
        // DocId.
        mrzResult.docId = [line2MatchedArray[1] stringByReplacingOccurrencesOfString:@"<" withString:@""];
        if (![self verifyString:line2MatchedArray[1] specifyChar:[dlrLineTextResultsArray[1] characterAtIndex:9]]) {// Check digital of document number
            mrzResult.isVerified = NO;
        }
        
        // Nationality.
        mrzResult.nationality = [line2MatchedArray[2] stringByReplacingOccurrencesOfString:@"<" withString:@""];
        
        // Birth date.
        NSMutableString *dateOfBirth = [NSMutableString string];
        [dateOfBirth appendString:line2MatchedArray[4]];
        [dateOfBirth appendString:@"-"];
        [dateOfBirth appendString:line2MatchedArray[5]];
        [dateOfBirth appendString:@"-"];
        [dateOfBirth appendString:line2MatchedArray[6]];
        
        mrzResult.dateOfBirth = dateOfBirth;
        
        if (![self verifyString:line2MatchedArray[3] specifyChar:[dlrLineTextResultsArray[1] characterAtIndex:19]]) {// Check digital of birth date
            mrzResult.isVerified = NO;
        }
        
        // Gender.
        mrzResult.gender = [line2MatchedArray[7] stringByReplacingOccurrencesOfString:@"<" withString:@"U"];
        
        // Date of expiration.
        NSMutableString *dateOfExpiration = [NSMutableString string];
        [dateOfExpiration appendString:line2MatchedArray[9]];
        [dateOfExpiration appendString:@"-"];
        [dateOfExpiration appendString:line2MatchedArray[10]];
        [dateOfExpiration appendString:@"-"];
        [dateOfExpiration appendString:line2MatchedArray[11]];
        
        mrzResult.dateOfExpiration = dateOfExpiration;
        
        if (![self verifyString:line2MatchedArray[8] specifyChar:[dlrLineTextResultsArray[1] characterAtIndex:27]]) {// check digital of expiration date
            mrzResult.isVerified = NO;
        }
        
        // Check all.
        NSMutableString *checkAllStr = [NSMutableString string];
        [checkAllStr appendString:[dlrLineTextResultsArray[1] substringWithRange:NSMakeRange(0, 10 - 0)]];
        [checkAllStr appendString:[dlrLineTextResultsArray[1] substringWithRange:NSMakeRange(13, 20 - 13)]];
        [checkAllStr appendString:[dlrLineTextResultsArray[1] substringWithRange:NSMakeRange(21, 43 - 21)]];
        if (![self verifyString:line2MatchedArray[12] specifyChar:[dlrLineTextResultsArray[1] characterAtIndex:42]] ||
            ![self verifyString:checkAllStr specifyChar:[dlrLineTextResultsArray[1] characterAtIndex:43]]) {// check digital of all
            mrzResult.isVerified = NO;
        }
    }
    
    return mrzResult;
}

+ (nullable iMRZResult *)getMRVBResultWith:(NSArray<NSString *> *)dlrLineTextResultsArray {
    iMRZResult *mrzResult = [[iMRZResult alloc] init];
    mrzResult.isParsed = YES;
    
    // MRZText.
    NSMutableString *mrzText = [NSMutableString string];
    [mrzText appendString:dlrLineTextResultsArray[0]];
    [mrzText appendString:@"\n"];
    [mrzText appendString:dlrLineTextResultsArray[1]];
    mrzResult.mrzText = mrzText;
    
    NSArray *line1MatchedArray = [self matchString:dlrLineTextResultsArray[0] regexString:MRVB_LINE1_REGEX];
    NSArray *line2MatchedArray = [self matchString:dlrLineTextResultsArray[1] regexString:MRVB_LINE2_REGEX];
    
    if (line1MatchedArray.count == 0 || line2MatchedArray.count == 0) {
        mrzResult.isParsed = NO;
        return mrzResult;
    }
    
    mrzResult.docType = @"visa-b";
    mrzResult.isVerified = YES;
    
    // Line1.
    if (line1MatchedArray.count != 0) {
        mrzResult.issuer = [line1MatchedArray[1] stringByReplacingOccurrencesOfString:@"<" withString:@""];

        NSString* name = line1MatchedArray[2];
        NSRange range = [name rangeOfString:@"<<"];
        if (range.location == NSNotFound) {
            mrzResult.surname = @"";
            mrzResult.givenName = [name stringByReplacingOccurrencesOfString:@"<" withString:@" "];
        } else {
            mrzResult.surname = [[name substringToIndex:range.location] stringByReplacingOccurrencesOfString:@"<" withString:@" "];
            mrzResult.givenName = [[name substringFromIndex:range.location + range.length] stringByReplacingOccurrencesOfString:@"<" withString:@" "];
            if ([mrzResult.givenName stringByReplacingOccurrencesOfString:@" " withString:@""].length == 0) {
                mrzResult.givenName = mrzResult.surname;
                mrzResult.surname = @"";
            }
        }           
    }
    
    // Line2.
    if (line2MatchedArray.count != 0) {
        // DocId.
        mrzResult.docId = [line2MatchedArray[1] stringByReplacingOccurrencesOfString:@"<" withString:@""];
        if (![self verifyString:line2MatchedArray[1] specifyChar:[dlrLineTextResultsArray[1] characterAtIndex:9]]) {// Check digital of document number
            mrzResult.isVerified = NO;
        }
        
        // Nationality.
        mrzResult.nationality = [line2MatchedArray[2] stringByReplacingOccurrencesOfString:@"<" withString:@""];
        
        // Birth date.
        NSMutableString *dateOfBirth = [NSMutableString string];
        [dateOfBirth appendString:line2MatchedArray[4]];
        [dateOfBirth appendString:@"-"];
        [dateOfBirth appendString:line2MatchedArray[5]];
        [dateOfBirth appendString:@"-"];
        [dateOfBirth appendString:line2MatchedArray[6]];
        
        mrzResult.dateOfBirth = dateOfBirth;
        
        if (![self verifyString:line2MatchedArray[3] specifyChar:[dlrLineTextResultsArray[1] characterAtIndex:19]]) {// Check digital of birth date
            mrzResult.isVerified = NO;
        }
        
        // Gender.
        mrzResult.gender = [line2MatchedArray[7] stringByReplacingOccurrencesOfString:@"<" withString:@"U"];
        
        // Date of expiration.
        NSMutableString *dateOfExpiration = [NSMutableString string];
        [dateOfExpiration appendString:line2MatchedArray[9]];
        [dateOfExpiration appendString:@"-"];
        [dateOfExpiration appendString:line2MatchedArray[10]];
        [dateOfExpiration appendString:@"-"];
        [dateOfExpiration appendString:line2MatchedArray[11]];
        
        mrzResult.dateOfExpiration = dateOfExpiration;
        
        if (![self verifyString:line2MatchedArray[8] specifyChar:[dlrLineTextResultsArray[1] characterAtIndex:27]]) {// check digital of expiration date
            mrzResult.isVerified = NO;
        }
    }

    return mrzResult;
}

+ (nullable iMRZResult *)getMRVAResultWith:(NSArray<NSString *> *)dlrLineTextResultsArray {
    iMRZResult *mrzResult = [[iMRZResult alloc] init];
    mrzResult.isParsed = YES;
    
    // MRZText.
    NSMutableString *mrzText = [NSMutableString string];
    [mrzText appendString:dlrLineTextResultsArray[0]];
    [mrzText appendString:@"\n"];
    [mrzText appendString:dlrLineTextResultsArray[1]];
    mrzResult.mrzText = mrzText;
        
    
    NSArray *line1MatchedArray = [self matchString:dlrLineTextResultsArray[0] regexString:MRVA_LINE1_REGEX];
    NSArray *line2MatchedArray = [self matchString:dlrLineTextResultsArray[1] regexString:MRVA_LINE2_REGEX];
    if (line1MatchedArray.count == 0 || line2MatchedArray.count == 0) {
        mrzResult.isParsed = NO;
        return mrzResult;
    }
    
    mrzResult.docType = @"visa-a";
    mrzResult.isVerified = YES;
    
    // Line1.
    if (line1MatchedArray.count != 0) {
        mrzResult.issuer = [line1MatchedArray[1] stringByReplacingOccurrencesOfString:@"<" withString:@""];
        
        NSString* name = line1MatchedArray[2];
        NSRange range = [name rangeOfString:@"<<"];
        if (range.location == NSNotFound) {
            mrzResult.surname = @"";
            mrzResult.givenName = [name stringByReplacingOccurrencesOfString:@"<" withString:@" "];
        } else {
            mrzResult.surname = [[name substringToIndex:range.location] stringByReplacingOccurrencesOfString:@"<" withString:@" "];
            mrzResult.givenName = [[name substringFromIndex:range.location + range.length] stringByReplacingOccurrencesOfString:@"<" withString:@" "];
            if ([mrzResult.givenName stringByReplacingOccurrencesOfString:@" " withString:@""].length == 0) {
                mrzResult.givenName = mrzResult.surname;
                mrzResult.surname = @"";
            }
        }           
    }
    
    // Line2.
    if (line2MatchedArray.count != 0) {
        // DocId.
        mrzResult.docId = [line2MatchedArray[1] stringByReplacingOccurrencesOfString:@"<" withString:@""];
        if (![self verifyString:line2MatchedArray[1] specifyChar:[dlrLineTextResultsArray[1] characterAtIndex:9]]) {// Check digital of document number
            mrzResult.isVerified = NO;
        }
        
        // Nationality.
        mrzResult.nationality = [line2MatchedArray[2] stringByReplacingOccurrencesOfString:@"<" withString:@""];
        
        // Birth date.
        NSMutableString *dateOfBirth = [NSMutableString string];
        [dateOfBirth appendString:line2MatchedArray[4]];
        [dateOfBirth appendString:@"-"];
        [dateOfBirth appendString:line2MatchedArray[5]];
        [dateOfBirth appendString:@"-"];
        [dateOfBirth appendString:line2MatchedArray[6]];
        
        mrzResult.dateOfBirth = dateOfBirth;
        
        if (![self verifyString:line2MatchedArray[3] specifyChar:[dlrLineTextResultsArray[1] characterAtIndex:19]]) {// Check digital of birth date
            mrzResult.isVerified = NO;
        }
        
        // Gender.
        mrzResult.gender = [line2MatchedArray[7] stringByReplacingOccurrencesOfString:@"<" withString:@"U"];
        
        // Date of expiration.
        NSMutableString *dateOfExpiration = [NSMutableString string];
        [dateOfExpiration appendString:line2MatchedArray[9]];
        [dateOfExpiration appendString:@"-"];
        [dateOfExpiration appendString:line2MatchedArray[10]];
        [dateOfExpiration appendString:@"-"];
        [dateOfExpiration appendString:line2MatchedArray[11]];
        
        mrzResult.dateOfExpiration = dateOfExpiration;
        
        if (![self verifyString:line2MatchedArray[8] specifyChar:[dlrLineTextResultsArray[1] characterAtIndex:27]]) {// check digital of expiration date
            mrzResult.isVerified = NO;
        }
    }
    
    return mrzResult;
}

// MARK: - Vertify
+ (BOOL)verifyString:(NSString *)string specifyChar:(char)c {
    if (c == '<' || (c >= '0' && c <= '9')) {
        if (c == '<') {
            return [self weightCalculationOfString:string] == 0;
        } else {
            int cValue = c - '0';
            return [self weightCalculationOfString:string] == cValue;
        }
    } else {
        return NO;
    }
}

+ (int)weightCalculationOfString:(NSString *)source {
    NSString *weightStr = @"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    NSArray<NSNumber *> *weightValue = @[@(7), @(3), @(1)];
    int totalValue = 0;
    for (int i = 0; i < source.length; i++) {
        char c = [source characterAtIndex:i];
        if (c == '<') {
            continue;
        }
        int indexOfC = 0;
        for (int j = 0; j < weightStr.length; j++) {
            if ([weightStr characterAtIndex:j] == c) {
                indexOfC = j;
                break;
            }
        }
        totalValue += indexOfC * [weightValue[i % 3] intValue];
    }
    totalValue %= 10;
    return totalValue;
}

+ (NSArray<NSString *> *)matchString:(NSString *)string regexString:(NSString *)regexStr {
    NSRegularExpression *regularExpression = [NSRegularExpression regularExpressionWithPattern:regexStr options:NSRegularExpressionCaseInsensitive error:nil];
    NSArray *matches = [regularExpression matchesInString:string options:0 range:NSMakeRange(0, string.length)];
    NSMutableArray *array = [NSMutableArray array];
    
    for (NSTextCheckingResult *match in matches) {
        for (int i = 0; i < match.numberOfRanges; i++) {
            NSString *component = [string substringWithRange:[match rangeAtIndex:i]];
            [array addObject:component];
        }
    }
    
    return array;
}

@end
