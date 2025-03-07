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
    public var license: String!
    @available(*, deprecated, message: "Use `templateFile` instead")
    public var templateFilePath: String?
    public var templateFile: String?
    public var isTorchButtonVisible: Bool = true
    public var isBeepEnabled: Bool = true
    public var isCloseButtonVisible: Bool = true
    public var documentType: DocumentType = .all
    public var isGuideFrameVisible: Bool = true
    public var isCameraToggleButtonVisible: Bool = false
}
