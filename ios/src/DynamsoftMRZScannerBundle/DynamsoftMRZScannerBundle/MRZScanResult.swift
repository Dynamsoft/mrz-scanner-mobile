//
//  MRZScanResult.swift
//  DynamsoftMRZScannerBundle
//
//  Copyright © Dynamsoft Corporation.  All rights reserved.
//

import Foundation
import UIKit
import DynamsoftCaptureVisionBundle

@objc(DSResultStatus)
public enum ResultStatus:Int {
    case finished
    case canceled
    case exception
}

@objc(DSDocumentSide)
public enum DocumentSide: Int {
    case mrz      // the side of the document that contains the MRZ
    case opposite // the other side of the document (only applicable when MRZ and portrait are on different sides)
}

@objcMembers
@objc(DSMRZData)
public class MRZData:NSObject {
    public let mrzText: String
    public let firstName: String
    public let lastName: String
    public let sex: String
    public let age: Int
    public let issuingState: String
    public let issuingStateRaw: String
    public let nationality: String
    public let nationalityRaw: String
    public let dateOfBirth: String
    public let dateOfExpire: String
    public let documentType: String
    public let documentNumber: String
    public let personalNumber: String?
    public let optionalData1: String?
    public let optionalData2: String?
    
    init(mrzText: String, firstName: String, lastName: String, sex: String, age: Int, issuingState: String, issuingStateRaw: String, nationality: String, nationalityRaw: String, dateOfBirth: String, dateOfExpire: String, documentType: String, documentNumber: String, personalNumber: String? = nil, optionalData1: String? = nil, optionalData2: String? = nil) {
        self.mrzText = mrzText
        self.firstName = firstName
        self.lastName = lastName
        self.sex = sex
        self.age = age
        self.issuingState = issuingState
        self.issuingStateRaw = issuingStateRaw
        self.nationality = nationality
        self.nationalityRaw = nationalityRaw
        self.dateOfBirth = dateOfBirth
        self.dateOfExpire = dateOfExpire
        self.documentType = documentType
        self.documentNumber = documentNumber
        self.personalNumber = personalNumber
        self.optionalData1 = optionalData1
        self.optionalData2 = optionalData2
    }
}

@objcMembers
@objc(DSMRZScanResult)
public class MRZScanResult: NSObject {
    public let resultStatus:ResultStatus
    public let errorCode: Int
    public let errorString: String?
    public let data: MRZData?
    internal var primaryDocumentImage: ImageData?
    internal var secondaryDocumentImage: ImageData?
    internal var primaryOriginalImage: ImageData?
    internal var secondaryOriginalImage: ImageData?
    internal var portraitImage: ImageData?
    init(resultStatus: ResultStatus, errorCode: Int = 0, errorString: String? = nil, data: MRZData? = nil, primaryDocumentImage: ImageData? = nil, secondaryDocumentImage: ImageData? = nil, primaryOriginalImage: ImageData? = nil, secondaryOriginalImage: ImageData? = nil, portraitImage: ImageData? = nil) {
        self.resultStatus = resultStatus
        self.errorCode = errorCode
        self.errorString = errorString
        self.data = data
        self.primaryDocumentImage = primaryDocumentImage
        self.secondaryDocumentImage = secondaryDocumentImage
        self.primaryOriginalImage = primaryOriginalImage
        self.secondaryOriginalImage = secondaryOriginalImage
        self.portraitImage = portraitImage
    }
    
    public func getPortraitImage() -> ImageData? {
        return portraitImage
    }
    
    public func getDocumentImage(_ side: DocumentSide) -> ImageData? {
        switch side {
        case .mrz: return primaryDocumentImage
        case .opposite: return secondaryDocumentImage
        }
    }
    
    public func getOriginalImage(_ side: DocumentSide) -> ImageData? {
        switch side {
        case .mrz: return primaryOriginalImage
        case .opposite: return secondaryOriginalImage
        }
    }
}
