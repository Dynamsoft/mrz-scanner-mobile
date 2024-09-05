import UIKit
import DynamsoftCaptureVisionRouter
import DynamsoftUtility
import DynamsoftLabelRecognizer
import DynamsoftCodeParser
import DynamsoftCameraEnhancer
import DynamsoftLicense

let kAllTemplateNameList: [String] = ["ReadId", "ReadPassport", "ReadPassportAndId"]

var defaultTemplateIndex: Int = 2

class CameraViewController: BaseViewController {

    // CaptureVisionRouter is the class for you to configure settings, retrieve images, start MRZ scanning and receive results.
    private var cvr: CaptureVisionRouter!

    // CameraEnhancer is the class for controlling the camera and obtaining high-quality video input.
    private var dce: CameraEnhancer!
    private var dceView: CameraView!
    private var dlrDrawingLayer: DrawingLayer!
    private var resultFilter: MultiFrameResultCrossFilter!
    
    private var currentTemplateName = kAllTemplateNameList[defaultTemplateIndex]
    private var mrzResultModel: MRZResultModel!
    private var isBeep: Bool = true
    
    private lazy var resultView: UILabel = {
        let resultView = UILabel(frame: CGRectZero)
        resultView.numberOfLines = 0
        resultView.translatesAutoresizingMaskIntoConstraints = false
        return resultView
    }()
    
    private lazy var beepButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "music-mute"), for: .normal)
        button.setImage(UIImage(named: "music"), for: .selected)
        button.addTarget(self, action: #selector(beepButtonTouchUp), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.sizeToFit()
        button.backgroundColor = .clear
        button.isSelected = true
        return button
    }()
    
     private lazy var scanLine: UIImageView = {
         let imageView = UIImageView(image: UIImage(named: "scan"))
         imageView.translatesAutoresizingMaskIntoConstraints = false
         imageView.sizeToFit()
         return imageView
     }()
    
    lazy var switchTemplateControl: UISegmentedControl = {
        let segmentedControl = UISegmentedControl(frame: CGRectZero)
        segmentedControl.backgroundColor = .black.withAlphaComponent(0.5)
        segmentedControl.insertSegment(withTitle: "ID", at: 0, animated: true)
        segmentedControl.insertSegment(withTitle: "Passport", at: 1, animated: true)
        segmentedControl.insertSegment(withTitle: "Both", at: 2, animated: true)
        segmentedControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor : UIColor.white], for: .normal)
        segmentedControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor : UIColor.white], for: .selected)
        segmentedControl.selectedSegmentIndex = defaultTemplateIndex
        segmentedControl.selectedSegmentTintColor = UIColor(red: 254 / 255.0, green: 142 / 255.0, blue: 20 / 255.0, alpha: 1)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.addTarget(self, action: #selector(templateControlValueChanged(_:)), for: .valueChanged)
        return segmentedControl
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setLicense()
        configureDCE()
        configureCVR()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = false;
        self.navigationController?.navigationBar.tintColor = .white
        self.navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.white]
        self.navigationController?.navigationBar.barTintColor = UIColor(red: 43 / 255.0, green: 43 / 255.0, blue: 43 / 255.0, alpha: 1)
        
        resetUI()
        dce.open()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Start capturing.
        // The template name is a string specified in the template file. 
        // In this sample we can use "ReadPassportAndId", "ReadId" and "ReadPassport".
        // Here the template name is what the user selected on the UI.
        // If failed, it shows an error message that describes the reasons.
        // License error can be one of the reason of a failure. Besure that you have a valid license when starting capturing
        cvr.startCapturing(currentTemplateName) {
            [unowned self] isSuccess, error in
            if let error = error {
                self.displayCaptureError(error.localizedDescription)
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dce.close()
        cvr.stopCapturing()
    }

}

// MARK: - Actions.
extension CameraViewController {
    @objc func beepButtonTouchUp() {
        beepButton.isSelected = !beepButton.isSelected
        isBeep = beepButton.isSelected
    }
    
    @objc func templateControlValueChanged(_ control: UISegmentedControl) -> Void {
        cvr.stopCapturing()
        currentTemplateName = kAllTemplateNameList[control.selectedSegmentIndex]
        cvr.startCapturing(currentTemplateName) {
            [unowned self] isSuccess, error in
            if let error = error {
                self.displayCaptureError(error.localizedDescription)
            }
        }
    }
}

// MARK: - UI Config.
extension CameraViewController {
    private func configureCVR() -> Void {
        cvr = CaptureVisionRouter()
        cvr.addResultReceiver(self)

        // Initialize settings from the template file.
        // The template file include 3 templates which are:
        // "ReadPassportAndId": Process both passport and ID.
        // "ReadId": Process ID only.
        // "ReadPassport": Process passport only.
        // You can specify different template names when triggering method startCapturing() to implement different processing tasks.               
        let mrzTemplatePath = "MRZScanner.json"
        try? cvr.initSettingsFromFile(mrzTemplatePath)
        
        // Set the input.
        try? cvr.setInput(dce)

        // Enable the multi-frame cross verification feature. It will improve the accuracy of the MRZ scanning.
        resultFilter = MultiFrameResultCrossFilter()
        resultFilter.enableResultCrossVerification(.textLine, isEnabled: true)
        cvr.addResultFilter(resultFilter)
    }
    
    private func configureDCE() -> Void {
        dceView = CameraView(frame: CGRect(x: 0, y: kNavigationBarFullHeight, width: kScreenWidth, height: kScreenHeight - kNavigationBarFullHeight))
        dceView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.addSubview(dceView)
        
        dlrDrawingLayer = dceView.getDrawingLayer(DrawingLayerId.DLR.rawValue)
        dlrDrawingLayer.visible = true
        dce = CameraEnhancer(view: dceView)
        
        // Enable the frame filter feature. It will improve the accuracy of the MRZ scanning.
        dce.enableEnhancedFeatures(.frameFilter)
    }
    
    private func setupUI() -> Void {
        self.view.addSubview(beepButton)
        self.view.addSubview(scanLine)
        self.view.addSubview(resultView)
        self.view.addSubview(switchTemplateControl)
        self.view.bringSubviewToFront(super.enterpriseInfo)
        
        NSLayoutConstraint.activate([
            beepButton.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 25),
            beepButton.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 25)
        ])
        
        NSLayoutConstraint.activate([
            scanLine.centerXAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor),
            scanLine.centerYAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerYAnchor)
        ])

        NSLayoutConstraint.activate([
            switchTemplateControl.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 45),
            switchTemplateControl.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -45),
            switchTemplateControl.heightAnchor.constraint(equalToConstant: 54),
            switchTemplateControl.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -100)
        ])
        
        NSLayoutConstraint.activate([
            resultView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 45),
            resultView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -45),
            resultView.topAnchor.constraint(equalTo: scanLine.bottomAnchor, constant: 10),
            resultView.bottomAnchor.constraint(equalTo: switchTemplateControl.topAnchor, constant: -10)
        ])

    }
    
    private func resetUI() -> Void {
        mrzResultModel = MRZResultModel()

        // DrawingItem in this sample is the green quadrilateral that highlights the recognized text.
        // Clear the DrawingItem before you leave the camera page.
        dlrDrawingLayer.clearDrawingItems()
        resultView.text = ""
    }
}

// MARK: - CapturedResultReceiver.
extension CameraViewController: CapturedResultReceiver {
    // Implement this method to receive raw MRZ recognized results. It includes the string only.
    func onRecognizedTextLinesReceived(_ result: RecognizedTextLinesResult) {
        guard let items = result.items else {
            return
        }
       
        mrzResultModel.recognizedText = items.first?.text
    }
    // Implement this method to receive parsed MRZ results. It includes the detailed information.
    func onParsedResultsReceived(_ result: ParsedResult) {
        
        guard let recognizedText = mrzResultModel.recognizedText, recognizedText.count > 0 else {
            return
        }
        
        // ParsedResult contains all parsed results that are captured from an image.
        // In the ParsedResult object, the property items is an array of ParsedResultItems.
        // Each ParsedResultItem is a result parsed from a single MRZ text.
        // If the ParsedResultItem is empty or the parsed content is empty, the following code will show the recognized text on the view.
        guard let items = result.items else {
            displayDCPParsedFailure(recognizedText: recognizedText)
            return
        }
        
        guard let firstItem = items.first, firstItem.parsedFields.keys.isEmpty == false else {
            displayDCPParsedFailure(recognizedText: recognizedText)
            return
        }
        


        mrzResultModel.parsedResultItem = firstItem

        guard mrzResultModel.determineWhetherIsLegal() == true else {
            displayDCPParsedFailure(recognizedText: recognizedText)
            return
        }
        
        if isBeep {
            Feedback.beep()
        }
        cvr.stopCapturing()

        // There is a image buffer storing the video frames that captured by the camera.
        // Clear the remaining images from the buffer before leaving the camera view.
        dce.clearBuffer()
        
        // Go the the result view if the MRZ is parsed successfully.
        DispatchQueue.main.async {
            let resultVC = MRZResultViewController()
            resultVC.mrzResultModel = self.mrzResultModel
            self.navigationController?.pushViewController(resultVC, animated: true)
        }
    }
}

// MARK: - General methods.
extension CameraViewController {
    private func displayCaptureError(_ msg: String) {
        DispatchQueue.main.async {
            DSToolsManager.shared.addTipView(to: self, tip: msg)
        }
    }
    
    func displayDCPParsedFailure(recognizedText: String) -> Void {
        DispatchQueue.main.async {
            self.resultView.attributedText = DSToolsManager.shared.constructParsedTipContentWith(recognizedText: recognizedText)
        }
    }
}

// MARK: LicenseVerificationListener
extension CameraViewController:LicenseVerificationListener {
    
    func setLicense() {
        // Initialize the license.
        // The license string here is a trial license. Note that network connection is required for this license to work.
        // You can request an extension via the following link: https://www.dynamsoft.com/customer/license/trialLicense?product=mrz&utm_source=samples&package=ios
        LicenseManager.initLicense("DLS2eyJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSJ9", verificationDelegate: self)
    }
    
    func onLicenseVerified(_ isSuccess: Bool, error: Error?) {
        if !isSuccess {
            if let error = error {
                DispatchQueue.main.async {
                    DSToolsManager.shared.addTipView(to: self, tip: "License initialization failed:" + error.localizedDescription)
                }
            }
        }
    }
}

