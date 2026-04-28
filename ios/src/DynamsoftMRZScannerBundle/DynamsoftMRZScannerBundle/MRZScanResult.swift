//
//  MRZScanResult.swift
//  DynamsoftMRZScannerBundle
//
//  Copyright © Dynamsoft Corporation.  All rights reserved.
//

import Foundation

@objc(DSResultStatus)
public enum ResultStatus:Int {
    case finished
    case canceled
    case exception
}

@objcMembers
@objc(DSMRZData)
public class MRZData:NSObject {
    public let firstName: String
    public let lastName: String
    public let sex: String
    public let issuingState: String
    public let nationality: String
    public let dateOfBirth: String
    public let dateOfExpire: String
    public let documentType: String
    public let documentNumber: String
    public let age: Int
    public let mrzText: String
    init(firstName: String, lastName: String, sex: String, issuingState: String, nationality: String, dateOfBirth: String, dateOfExpire: String, documentType: String, documentNumber: String, age: Int, mrzText: String) {
        self.firstName = firstName
        self.lastName = lastName
        self.sex = sex
        self.issuingState = issuingState
        self.nationality = nationality
        self.dateOfBirth = dateOfBirth
        self.dateOfExpire = dateOfExpire
        self.documentType = documentType
        self.documentNumber = documentNumber
        self.age = age
        self.mrzText = mrzText
    }
}

@objcMembers
@objc(DSMRZScanResult)
public class MRZScanResult: NSObject {
    public let resultStatus:ResultStatus
    public let data: MRZData?
    public let errorCode: Int
    public let errorString: String?
    init(resultStatus: ResultStatus, mrzdata: MRZData? = nil, errorCode: Int = 0, errorString: String? = nil) {
        self.resultStatus = resultStatus
        self.data = mrzdata
        self.errorCode = errorCode
        self.errorString = errorString
    }
}
