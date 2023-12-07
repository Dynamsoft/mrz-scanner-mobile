//
//  DynamsoftMRZRecognizer.h
//  DynamsoftMRZRecognizerSDK

#import <Foundation/Foundation.h>
#import <DynamsoftLabelRecognizer/DynamsoftLabelRecognizer.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, EnumMRTDDocumentType) {
    EnumMRTDDocumentType_MDT_ALL           = 0,
    EnumMRTDDocumentType_MDT_PASSSPORT,
    EnumMRTDDocumentType_MDT_ID_CARD,
    EnumMRTDDocumentType_MDT_VISA
    
};

@interface iMRZResult : NSObject

@property (nonatomic, copy) NSString *docId;

@property (nonatomic, copy) NSString *nationality;

@property (nonatomic, copy) NSString *issuer;

@property (nonatomic, copy) NSString *gender;

@property (nonatomic, copy) NSString *surname;

@property (nonatomic, copy) NSString *givenName;

@property (nonatomic, copy) NSString *dateOfBirth;

@property (nonatomic, copy) NSString *dateOfExpiration;

@property (nonatomic, copy) NSString *mrzText;

@property (nonatomic, copy) NSString *docType;

@property (nonatomic, assign) BOOL isParsed;

@property (nonatomic, assign) BOOL isVerified;

@end

@protocol MRZResultListener <NSObject>

- (void)mrzResultCallback:(NSInteger)frameId
                imageData:(nonnull iImageData *)imageData
                   result:(nullable iMRZResult * )result;

@required

@end

@interface DynamsoftMRZRecognizer : DynamsoftLabelRecognizer

- (instancetype)init;

- (instancetype)initWith:(EnumMRTDDocumentType)type;

- (void)setMRZResultListener:(nullable id<MRZResultListener>)listener;

- (nullable iMRZResult *)recognizeMRZFromFile:(NSString *)fileName
                                        error:(NSError * _Nullable * _Nullable)error
NS_SWIFT_NAME(recognizeMRZFromFile(_:));

- (nullable iMRZResult *)recognizeMRZFromBuffer:(iImageData *)imageData
                                          error:(NSError * _Nullable * _Nullable)error
NS_SWIFT_NAME(recognizeMRZFromBuffer(_:));

- (nullable iMRZResult *)recognizeMRZFromImage:(UIImage *)image
                                         error:(NSError * _Nullable * _Nullable)error
NS_SWIFT_NAME(recognizeMRZFromImage(_:));

- (nullable iMRZResult *)recognizeMRZFileInMemory:(NSData *)fileBytes
                                            error:(NSError * _Nullable * _Nullable)error
NS_SWIFT_NAME(recognizeMRZInMemory(_:));

@end

NS_ASSUME_NONNULL_END
