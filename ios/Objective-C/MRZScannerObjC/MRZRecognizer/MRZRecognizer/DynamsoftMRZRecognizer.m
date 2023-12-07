//
//  DynamsoftMRZRecognizer.m
//  DynamsoftMRZRecognizerSDK

#import "DynamsoftMRZRecognizer.h"
#import "MRZConverter.h"

@implementation iMRZResult

- (instancetype)init {
    self = [super init];
    if (self) {

    }
    return self;
}

@end

@interface DynamsoftMRZRecognizer ()<LabelResultListener>

@property (nonatomic, weak, nullable) id<MRZResultListener> mrzDelegate;

@property (nonatomic, assign) EnumMRTDDocumentType mrtType;

@end

@implementation DynamsoftMRZRecognizer

- (instancetype)init {
    self = [super init];
    if (self) {
        self.mrtType = EnumMRTDDocumentType_MDT_ALL;
        [self configureParameters];
    }
    return self;
}

- (instancetype)initWith:(EnumMRTDDocumentType)type {
    self = [super init];
    if (self) {
        self.mrtType = type;
        [self configureParameters];
    }
    return self;
}

- (void)configureParameters {

    
    NSBundle *bundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"Resource" ofType:@"bundle"]];

    // 1. Append character model.
    NSString *caffemodelPath = [bundle pathForResource:@"MRZ" ofType:@"caffemodel"];
    NSData *caffemodelData = [NSData dataWithContentsOfFile:caffemodelPath];

    NSString *prototxtPath = [bundle pathForResource:@"MRZ" ofType:@"prototxt"];
    NSData *prototxtData = [NSData dataWithContentsOfFile:prototxtPath];

    NSString *txtPath = [bundle pathForResource:@"MRZ" ofType:@"txt"];
    NSData *txtData = [NSData dataWithContentsOfFile:txtPath];
    
    [DynamsoftMRZRecognizer appendCharacterModel:@"MRZ" prototxtBuffer:prototxtData txtBuffer:txtData characterModelBuffer:caffemodelData];
    
    // 2. Append runtimeSetting.
    NSString *mdtPath = @"";
    switch (self.mrtType) {
        case EnumMRTDDocumentType_MDT_ALL:
        {
            mdtPath =  [bundle pathForResource:@"MDT_ALL" ofType:@"json" inDirectory:@"Templates"];
            break;
        }
        case EnumMRTDDocumentType_MDT_PASSSPORT:
        {
            mdtPath =  [bundle pathForResource:@"MDT_PASSPORT" ofType:@"json" inDirectory:@"Templates"];
            break;
        }
        case EnumMRTDDocumentType_MDT_ID_CARD:
        {
            mdtPath =  [bundle pathForResource:@"MDT_ID_CARD" ofType:@"json" inDirectory:@"Templates"];
            break;
        }
        case EnumMRTDDocumentType_MDT_VISA:
        {
            mdtPath =  [bundle pathForResource:@"MDT_VISA" ofType:@"json" inDirectory:@"Templates"];
            break;
        }
        default:
            break;
    }
    
    NSData *jsonData = [[NSData alloc] initWithContentsOfFile:mdtPath];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSError *error = nil;
    [self initRuntimeSettings:jsonString error:&error];
}

- (void)setMRZResultListener:(id<MRZResultListener>)listener {
    self.mrzDelegate = listener;
    [super setLabelResultListener:self];
}

// MARK: - LabelResultListener
- (void)labelResultCallback:(NSInteger)frameId imageData:(iImageData *)imageData results:(NSArray<iDLRResult *> *)results {
    if (self.mrzDelegate != nil && [self.mrzDelegate respondsToSelector:@selector(mrzResultCallback:imageData:result:)]) {
        [self.mrzDelegate mrzResultCallback:frameId imageData:imageData result:[self getMRZResultWith:results]];
    }
}

// MARK: - Recognize methods
- (iMRZResult *)recognizeMRZFromFile:(NSString *)fileName error:(NSError * _Nullable __autoreleasing *)error {
    return [self getMRZResultWith:[self recognizeFile:fileName error:error]];
}

- (iMRZResult *)recognizeMRZFromBuffer:(iImageData *)imageData error:(NSError * _Nullable __autoreleasing *)error {
    return [self getMRZResultWith:[self recognizeBuffer:imageData error:error]];
}

- (iMRZResult *)recognizeMRZFromImage:(UIImage *)image error:(NSError * _Nullable __autoreleasing *)error {
    return [self getMRZResultWith:[self recognizeImage:image error:error]];
}

- (iMRZResult *)recognizeMRZFileInMemory:(NSData *)fileBytes error:(NSError * _Nullable __autoreleasing *)error {
    return [self getMRZResultWith:[self recognizeFileInMemory:fileBytes error:error]];
}

// MARK: - General methods
- (nullable iMRZResult *)getMRZResultWith:(nullable NSArray<iDLRResult *> *)results {
    NSMutableArray<NSString *> *dlrLineTextResults = [NSMutableArray array];
    for (iDLRResult *dlrResult in results) {
        for (iDLRLineResult *dlrlineResult in dlrResult.lineResults) {
            [dlrLineTextResults addObject:dlrlineResult.text];
        }
    }
    
    return [MRZConverter getMRZResultWith:dlrLineTextResults];
}

@end
