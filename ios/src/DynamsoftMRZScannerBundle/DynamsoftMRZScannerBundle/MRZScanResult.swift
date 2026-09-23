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

/// Error codes owned by the MRZ Scanner bundle, reported through ``MRZScanResult/errorCode``
/// alongside `.exception`. Capture Vision's own codes share the field but are all `<= 0`,
/// so the positive 1000...1999 range is reserved here and the sign tells the two apart.
@objc(DSMRZErrorCode)
public enum ErrorCode: Int {
    /// The user denied camera access. iOS prompts only once per install, so a route into
    /// Settings is the only remediation.
    case cameraPermissionDenied = 1001

    /// Camera access is withheld by device policy (Screen Time, MDM). The per-app toggle is
    /// absent from Settings in this state, so sending the user there is a dead end.
    case cameraPermissionRestricted = 1002
}

@objc(DSDocumentSide)
public enum DocumentSide: Int {
    case mrz      // the side carrying the MRZ
    case opposite // the other side, when MRZ and portrait are on different sides
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

    /// Per-field DCP validation status captured at parse time, keyed by DCP raw field name.
    /// Private so the non-@objc Dictionary doesn't break bridging on this @objcMembers class.
    private let fieldValidation: [String: ValidationStatus]

    /// Which DCP raw key held the document number for this scan, so
    /// `getFieldValidationStatus("documentNumber")` looks up the right one.
    private let documentNumberRawKey: String?

    /// Fails when a required field is absent, which is how frames carrying no MRZ at all — the
    /// opposite side of a document, say — are filtered out. A failed check digit does not fail
    /// the parse: per-field validation is captured instead for the caller to surface.
    init?(_ item: ParsedResultItem) {
        let fields = item.parsedFields
        guard let birthDay = fields["birthDay"], let birthMonth = fields["birthMonth"],
              let birthYear = fields["birthYear"], let expiryDay = fields["expiryDay"],
              let expiryMonth = fields["expiryMonth"], let expiryYear = fields["expiryYear"],
              let sex = fields["sex"], let issuingState = fields["issuingState"],
              let nationality = fields["nationality"] else { return nil }

        let birthYearInt = Self.fullBirthYear(birthYear)
        let numberKey = Self.documentNumberKeys(for: item.codeType).first { fields[$0] != nil }

        // line1 is present for every parsed MRZ, so joining matches the previous
        // "line1, then newline-prefixed lines" concatenation.
        self.mrzText = ["line1", "line2", "line3"].compactMap { fields[$0] }.joined(separator: "\n")
        self.firstName = fields["secondaryIdentifier"] ?? ""
        self.lastName = fields["primaryIdentifier"] ?? ""
        self.sex = sex
        self.age = Self.age(year: birthYearInt, month: birthMonth, day: birthDay)
        self.issuingState = issuingState
        self.issuingStateRaw = item.getFieldRawValue("issuingState")
        self.nationality = nationality
        self.nationalityRaw = item.getFieldRawValue("nationality")
        // Date components may be "XX" rather than a number, hence the "XX" fallbacks.
        self.dateOfBirth = (birthYearInt.map(String.init) ?? "XX") + "-" + birthMonth + "-" + birthDay
        self.dateOfExpire = (Int(expiryYear).map { String(2000 + $0) } ?? "XX")
            + "-" + expiryMonth + "-" + expiryDay
        self.documentType = item.codeType
        self.documentNumber = numberKey.flatMap { fields[$0] } ?? ""
        self.personalNumber = fields["personalNumber"]
        self.optionalData1 = item.getFieldRawValue("optionalData1")
        self.optionalData2 = item.getFieldRawValue("optionalData2")
        self.documentNumberRawKey = numberKey
        self.fieldValidation = Self.validatedFields.reduce(into: [String: ValidationStatus]()) {
            $0[$1] = item.getFieldValidationStatus($1)
        }
        super.init()
    }

    /// DCP validation status for a friendly field name — the same names as the properties above.
    /// Composite fields return worst-of: `.failed` if any failed, else `.succeeded` if any
    /// passed, else `.none`. Unknown and uncaptured names also return `.none`.
    public func getFieldValidationStatus(_ fieldName: String) -> ValidationStatus {
        // documentNumber's raw key varies by MRZ format, so it is resolved per scan.
        let keys = fieldName == "documentNumber"
            ? [documentNumberRawKey].compactMap { $0 }
            : Self.rawKeys[fieldName] ?? []

        var anySucceeded = false
        for key in keys {
            switch fieldValidation[key] ?? .none {
            case .failed: return .failed
            case .succeeded: anySucceeded = true
            default: break
            }
        }
        return anySucceeded ? .succeeded : .none
    }

    /// Friendly property name → the DCP raw key, or the keys a composite takes the worst of.
    private static let rawKeys: [String: [String]] = [
        "firstName": ["secondaryIdentifier"],
        "lastName": ["primaryIdentifier"],
        "sex": ["sex"],
        "nationality": ["nationality"],
        "issuingState": ["issuingState"],
        "personalNumber": ["personalNumber"],
        "optionalData1": ["optionalData1"],
        "optionalData2": ["optionalData2"],
        "dateOfBirth": ["dateOfBirth", "birthYear", "birthMonth", "birthDay"],
        "dateOfExpire": ["dateOfExpiry", "expiryYear", "expiryMonth", "expiryDay"],
        "mrzText": ["line1", "line2", "line3"],
    ]

    /// Raw DCP keys whose validation status is snapshotted at parse time.
    private static let validatedFields = [
        "line1", "line2", "line3",
        "primaryIdentifier", "secondaryIdentifier",
        "sex", "nationality", "issuingState",
        "dateOfBirth", "birthYear", "birthMonth", "birthDay",
        "dateOfExpiry", "expiryYear", "expiryMonth", "expiryDay",
        "passportNumber", "documentNumber", "longDocumentNumber",
        "personalNumber", "optionalData1", "optionalData2",
    ]

    /// Which raw key carries the document number depends on the MRZ format.
    private static func documentNumberKeys(for codeType: String) -> [String] {
        switch codeType {
        case "MRTD_TD1_ID":                       return ["documentNumber", "longDocumentNumber"]
        case "MRTD_TD2_ID", "MRTD_TD2_FRENCH_ID": return ["documentNumber"]
        case "MRTD_TD3_PASSPORT":                 return ["passportNumber"]
        default:                                  return []
        }
    }

    /// MRZ years are two digits; pick the century that does not place the date in the future.
    private static func fullBirthYear(_ raw: String) -> Int? {
        guard let year = Int(raw) else { return nil }
        let currentYear = Calendar.current.component(.year, from: Date())
        if year + 1900 > currentYear { return year }
        return year + (year + 2000 > currentYear ? 1900 : 2000)
    }

    /// Falls back to a year-only estimate when the month or day is unusable (e.g. "XX").
    private static func age(year: Int?, month: String, day: String) -> Int {
        guard let year = year else { return 0 }
        let calendar = Calendar.current
        guard let month = Int(month), let day = Int(day) else {
            return calendar.component(.year, from: Date()) - year
        }
        guard let birth = calendar.date(from: DateComponents(year: year, month: month, day: day)) else {
            return 0
        }
        return calendar.dateComponents([.year], from: birth, to: Date()).year ?? 0
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

    /// Images are filled in after construction, so they are not init parameters.
    init(resultStatus: ResultStatus, errorCode: Int = 0, errorString: String? = nil, data: MRZData? = nil) {
        self.resultStatus = resultStatus
        self.errorCode = errorCode
        self.errorString = errorString
        self.data = data
    }

    public func getPortraitImage() -> ImageData? {
        portraitImage
    }

    public func getDocumentImage(_ side: DocumentSide) -> ImageData? {
        side == .mrz ? primaryDocumentImage : secondaryDocumentImage
    }

    public func getOriginalImage(_ side: DocumentSide) -> ImageData? {
        side == .mrz ? primaryOriginalImage : secondaryOriginalImage
    }
}
