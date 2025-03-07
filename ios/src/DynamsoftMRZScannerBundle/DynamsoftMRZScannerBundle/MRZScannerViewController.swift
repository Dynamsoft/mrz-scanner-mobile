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
        if let path = config.templateFile {
            if path.hasPrefix("{") || path.hasPrefix("[") {
                do {
                    try cvr.initSettings(path)
                    name = ""
                } catch let error as NSError {
                    self.onScannedResult?(.init(resultStatus: .exception, errorCode: error.code, errorString: error.localizedDescription))
                    return
                }
            } else {
                do {
                    try cvr.initSettingsFromFile(path)
                    name = ""
                } catch let error as NSError {
                    self.onScannedResult?(.init(resultStatus: .exception, errorCode: error.code, errorString: error.localizedDescription))
                    return
                }
            }
        } else if let path = config.templateFilePath {
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
    
    lazy var closeButton: UIButton = {
        let bundle = Bundle(for: type(of: self))
        let button = UIButton()
        let closeImage = UIImage(named: "close", in: bundle, compatibleWith: nil)
        button.setImage(closeImage?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(onCloseButtonTouchUp), for: .touchUpInside)
        return button
    }()
    
    lazy var torchButton: UIButton = {
        let bundle = Bundle(for: type(of: self))
        let button = UIButton()
        let torchOffImage = UIImage(named: "torchOff", in: bundle, compatibleWith: nil)
        let torchOnImage = UIImage(named: "torchOn", in: bundle, compatibleWith: nil)
        button.setImage(torchOffImage?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.setImage(torchOnImage?.withRenderingMode(.alwaysOriginal), for: .selected)
        button.addTarget(self, action: #selector(onTorchButtonTouchUp), for: .touchUpInside)
        return button
    }()
    
    lazy var cameraButton: UIButton = {
        let bundle = Bundle(for: type(of: self))
        let button = UIButton()
        let switchCameraImage = UIImage(named: "switchCamera", in: bundle, compatibleWith: nil)
        button.setImage(switchCameraImage?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(onCameraButtonTouchUp), for: .touchUpInside)
        return button
    }()
    
    lazy var imageView: UIImageView = {
        let bundle = Bundle(for: type(of: self))
        let imageView = UIImageView(image: UIImage(named: "guide", in: bundle, compatibleWith: nil))
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
}

extension MRZScannerViewController {
    private func setupDCV() {
        cameraView.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(cameraView, at: 0)
        NSLayoutConstraint.activate([
            cameraView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cameraView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cameraView.topAnchor.constraint(equalTo: view.topAnchor),
            cameraView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        dce.cameraView = cameraView
        try! cvr.setInput(dce)
        cvr.addResultReceiver(self)
        let filter = MultiFrameResultCrossFilter()
        filter.enableResultCrossVerification(.textLine, isEnabled: true)
        cvr.addResultFilter(filter)
    }
    
    private func setupUI() {
        closeButton.isHidden = !config.isCloseButtonVisible
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(closeButton)
        
        torchButton.isHidden = !config.isTorchButtonVisible
        torchButton.translatesAutoresizingMaskIntoConstraints = false
        
        cameraButton.isHidden = !config.isCameraToggleButtonVisible
        cameraButton.translatesAutoresizingMaskIntoConstraints = false
        
        let stackView = UIStackView(arrangedSubviews: [torchButton, cameraButton])
        stackView.axis = .horizontal
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)

        imageView.isHidden = !config.isGuideFrameVisible
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        
        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: safeArea.centerYAnchor),
            imageView.widthAnchor.constraint(lessThanOrEqualTo: safeArea.widthAnchor, multiplier: 0.9),
            imageView.heightAnchor.constraint(lessThanOrEqualTo: safeArea.heightAnchor, multiplier: 0.9),
            
            closeButton.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 20),
            closeButton.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 20),
            
            stackView.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
            stackView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -50),
        ])
    }
    
    private func stop() {
        cvr.stopCapturing()
        dce.close()
        dce.clearBuffer()
    }
    
    @objc func onCloseButtonTouchUp() {
        stop()
        onScannedResult?(.init(resultStatus: .canceled))
    }
    
    @objc func onTorchButtonTouchUp(_ sender: Any) {
        guard let button = sender as? UIButton else { return }
        button.isSelected.toggle()
        if button.isSelected {
            dce.turnOnTorch()
        } else {
            dce.turnOffTorch()
        }
    }
    
    @objc func onCameraButtonTouchUp() {
        let position = dce.getCameraPosition()
        switch position {
        case .back, .backDualWideAuto, .backUltraWide:
            try? dce.selectCamera(with: .front)
            torchButton.isHidden = true
            torchButton.isSelected = false
        case .front:
            try? dce.selectCamera(with: .back)
            torchButton.isHidden = !config.isTorchButtonVisible
        @unknown default:
            try? dce.selectCamera(with: .back)
            torchButton.isHidden = !config.isTorchButtonVisible
        }
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

extension MRZScannerViewController: LicenseVerificationListener {
    
    private func setupLicense() {
        if let license = config.license {
            LicenseManager.initLicense(license, verificationDelegate: self)
        }
    }
    
    public func onLicenseVerified(_ isSuccess: Bool, error: (any Error)?) {
        
    }
}
