//
//  MRZScannerConfig.swift
//  DynamsoftMRZScannerBundle
//
//  Copyright © Dynamsoft Corporation.  All rights reserved.
//

import Foundation

@objc(DSDocumentType)
public enum DocumentType:Int {
    case all
    case id
    case passport
}

@objcMembers
@objc(DSMRZScannerConfig)
public class MRZScannerConfig: NSObject {
    public var license: String = ""
    public var templateFile: String?
    public var documentType: DocumentType = .all
    public var isGuideFrameVisible: Bool = true
    public var isCloseButtonVisible: Bool = true
    public var isTorchButtonVisible: Bool = true
    public var isCameraToggleButtonVisible: Bool = true
    public var isBeepEnabled: Bool = false
    public var isVibrateEnabled: Bool = false
    public var isBeepButtonVisible: Bool = true
    public var isVibrateButtonVisible: Bool = true
    public var returnDocumentImage: Bool = true
    public var returnPortraitImage: Bool = true
    public var returnOriginalImage: Bool = false
    public var isFormatSelectorVisible: Bool = true
    
    override public init() {
        super.init()
    }
    
    public init(license: String) {
        self.license = license
        super.init()
    }
}
