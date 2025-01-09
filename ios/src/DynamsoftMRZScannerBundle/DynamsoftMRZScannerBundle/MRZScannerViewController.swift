//
//  MRZScannerViewController.swift
//  DynamsoftMRZScannerBundle
//
//  Copyright © Dynamsoft Corporation.  All rights reserved.
//

import DynamsoftCore
import DynamsoftCameraEnhancer
import DynamsoftCaptureVisionRouter
import DynamsoftLicense
import DynamsoftUtility
import DynamsoftCodeParser
import DynamsoftLabelRecognizer

@objc(DSMRZScannerViewController)
public class MRZScannerViewController: UIViewController {
    
    let dce = CameraEnhancer()
    let cameraView = CameraView()
    let cvr = CaptureVisionRouter()
    let button = UIButton(type: .system)
    @objc public var config: MRZScannerConfig = .init()
    @objc public var onScannedResult: ((MRZScanResult) -> Void)?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupLicense()
        setupDCV()
        setupUI()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dce.open()
        var name: String
        switch config.documentType {
        case .all:
            name = "ReadPassportAndId"
        case .id:
            name = "ReadId"
        case .passport:
            name = "ReadPassport"
        }
        if let path = config.templateFilePath {
            do {
                try cvr.initSettingsFromFile(path)
                name = ""
            } catch let error as NSError {
                self.onScannedResult?(.init(resultStatus: .exception, errorCode: error.code, errorString: error.localizedDescription))
                return
            }
        }
        cvr.startCapturing(name) { isSuccess, error in
            if let error = error as? NSError, !isSuccess {
                self.onScannedResult?(.init(resultStatus: .exception, errorCode: error.code, errorString: error.localizedDescription))
            }
        }
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stop()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        let frame = view.bounds
        let orientation = UIDevice.current.orientation
        if orientation.isLandscape {
            button.frame = CGRect(x: 50, y: 20, width: 50, height: 50)
            cameraView.setTorchButton(frame: CGRect(x: frame.width / 2 - 25, y: frame.height - 100, width: 50, height: 50), torchOnImage: nil, torchOffImage: nil)
        } else if orientation.isPortrait {
            button.frame = CGRect(x: 20, y: 50, width: 50, height: 50)
            cameraView.setTorchButton(frame: CGRect(x: frame.width / 2 - 25, y: frame.height - 150, width: 50, height: 50), torchOnImage: nil, torchOffImage: nil)
        }
    }
}

extension MRZScannerViewController: LicenseVerificationListener {
    
    private func setupLicense() {
        if let license = config.license {
            LicenseManager.initLicense(license, verificationDelegate: self)
        }
    }
    
    public func onLicenseVerified(_ isSuccess: Bool, error: (any Error)?) {
        
    }
}

extension MRZScannerViewController {
    private func setupDCV() {
        cameraView.frame = view.bounds
        cameraView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        view.insertSubview(cameraView, at: 0)
        dce.cameraView = cameraView
        dce.enableEnhancedFeatures(.frameFilter)
        try! cvr.setInput(dce)
        cvr.addResultReceiver(self)
        let filter = MultiFrameResultCrossFilter()
        filter.enableResultCrossVerification(.textLine, isEnabled: true)
        cvr.addResultFilter(filter)
    }
    
    private func setupUI() {
        let frame = view.bounds
        cameraView.setTorchButton(frame: CGRect(x: frame.width / 2 - 25, y: frame.height - 150, width: 50, height: 50), torchOnImage: nil, torchOffImage: nil)
        cameraView.torchButtonVisible = config.isTorchButtonVisible
        
        let bundle = Bundle(for: type(of: self))
        let close = UIImage(named: "close", in: bundle, compatibleWith: nil)
        button.setImage(close?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.frame = CGRect(x: 20, y: 50, width: 50, height: 50)
        button.addTarget(self, action: #selector(buttonClicked), for: .touchUpInside)
        button.isHidden = !config.isCloseButtonVisible
        view.addSubview(button)
        
        let safeArea = view.safeAreaLayoutGuide
        let imageView = UIImageView(image: UIImage(named: "guide", in: bundle, compatibleWith: nil))
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = !config.isGuideFrameVisible
        view.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: safeArea.centerYAnchor),
            imageView.widthAnchor.constraint(lessThanOrEqualTo: safeArea.widthAnchor, multiplier: 0.9),
            imageView.heightAnchor.constraint(lessThanOrEqualTo: safeArea.heightAnchor, multiplier: 0.9)
        ])
    }
    
    private func stop() {
        cvr.stopCapturing()
        dce.close()
        dce.clearBuffer()
    }
    
    @objc func buttonClicked() {
        stop()
        onScannedResult?(.init(resultStatus: .canceled))
    }
}

extension MRZScannerViewController: CapturedResultReceiver {
    
    public func onParsedResultsReceived(_ result: ParsedResult) {
        guard let item = result.items?.first else { return }
        let mrzdata = convertToMRZData(item: item)
        if mrzdata != nil {
            stop()
            if config.isBeepEnabled {
                Feedback.beep()
            }
            onScannedResult?(.init(resultStatus: .finished, mrzdata: mrzdata))
        }
    }
    
    private func convertToMRZData(item: ParsedResultItem) -> MRZData? {
        let parsedFields = item.parsedFields
        let codeType = item.codeType
        
        var isValidated:Bool
        if codeType == "MRTD_TD1_ID" {
            isValidated = item.getFieldValidationStatus("line1") != .failed && item.getFieldValidationStatus("line2") != .failed && item.getFieldValidationStatus("line3") != .failed
        } else {
            isValidated = item.getFieldValidationStatus("line1") != .failed && item.getFieldValidationStatus("line2") != .failed
        }
        if !isValidated {
            return nil
        }
        guard let birthDay = parsedFields["birthDay"],
              let birthMonth = parsedFields["birthMonth"],
              let birthYear = parsedFields["birthYear"],
              let expiryDay = parsedFields["expiryDay"],
              let expiryMonth = parsedFields["expiryMonth"],
              let expiryYear = parsedFields["expiryYear"],
              let sex = parsedFields["sex"],
              var issuingState = parsedFields["issuingState"],
              var nationality = parsedFields["nationality"] else { return nil }
        
        let lastName = parsedFields["primaryIdentifier"] ?? ""
        let firstName = parsedFields["secondaryIdentifier"] ?? ""
        
        let birthYearInt = calculateBirthYear(birthYear)
        
        var birthYearString: String = "XX"
        if let birthYearInt = birthYearInt {
            birthYearString = String(birthYearInt)
        }
        let dateOfBirth = birthYearString + "-" + birthMonth + "-" + birthDay
        
        var age: Int = 0
        if let birthYear = birthYearInt {
            if let birthMonth = Int(birthMonth), let birthDay = Int(birthDay) {
                age = calculateAge(day: birthDay, month: birthMonth, year: birthYear) ?? 0
            } else {
                let currentYear = Calendar.current.component(.year, from: Date())
                age = currentYear - birthYear
            }
        }
        
        var expiryYeaString: String = "XX"
        if let expiryYearInt = Int(expiryYear) {
            expiryYeaString = String(2000 + expiryYearInt)
        }
        let dateOfExpire = expiryYeaString + "-" + expiryMonth + "-" + expiryDay
        
        var documentNumber = ""
        switch codeType {
        case "MRTD_TD1_ID":
            documentNumber = parsedFields["documentNumber"] ?? parsedFields["longDocumentNumber"] ?? ""
        case "MRTD_TD2_ID", "MRTD_TD2_FRENCH_ID":
            documentNumber = parsedFields["documentNumber"] ?? ""
        case "MRTD_TD3_PASSPORT":
            documentNumber = parsedFields["passportNumber"] ?? ""
        default:
            break
        }
        
        var mrzText:String = ""
        if let line1 = parsedFields["line1"] {
            mrzText += line1
        }
        if let line2 = parsedFields["line2"] {
            mrzText += "\n" + line2
        }
        if let line3 = parsedFields["line3"] {
            mrzText += "\n" + line3
        }

        issuingState = item.getFieldRawValue("issuingState")
        nationality = item.getFieldRawValue("nationality")
        let mrzData = MRZData(firstName: firstName, lastName: lastName, sex: sex, issuingState: issuingState, nationality: nationality, dateOfBirth: dateOfBirth, dateOfExpire: dateOfExpire, documentType: codeType, documentNumber: documentNumber, age: age, mrzText: mrzText)
        return mrzData
    }
    
    private func calculateBirthYear(_ birthYearString: String) -> Int? {
        guard let birthYear = Int(birthYearString) else { return nil }
        let currentYear = Calendar.current.component(.year, from: Date())
        var year: Int
        if birthYear + 1900 > currentYear {
            year = birthYear
        } else if birthYear + 2000 > currentYear {
            year = birthYear + 1900
        } else {
            year = birthYear + 2000
        }
        return year
    }
    
    private func calculateAge(day: Int, month: Int, year: Int) -> Int? {
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.day = day
        dateComponents.month = month
        dateComponents.year = year
        
        guard let birthDate = calendar.date(from: dateComponents) else {
            return nil
        }
        
        let currentDate = Date()
        
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: currentDate)
        return ageComponents.year
    }
}

extension MRZScannerViewController: CameraStateListener {
    public func onCameraStateChanged(_ currentState: CameraState) {

    }
}
