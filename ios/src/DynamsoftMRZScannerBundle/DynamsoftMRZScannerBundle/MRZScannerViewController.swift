//
//  MRZScannerViewController.swift
//  DynamsoftMRZScannerBundle
//
//  Copyright © Dynamsoft Corporation.  All rights reserved.

import AVFoundation
import DynamsoftCaptureVisionBundle

@objc(DSMRZScannerViewController)
public class MRZScannerViewController: UIViewController {

    /// Capture template and selector label per document type; `handleSelection` maps back by label.
    private static let documentTypeOptions: [(type: DocumentType, template: String, label: String)] = [
        (.all, "ReadPassportAndId", "Both"),
        (.id, "ReadId", "ID"),
        (.passport, "ReadPassport", "Passport"),
    ]

    var selectedOption: (type: DocumentType, template: String, label: String) {
        Self.documentTypeOptions.first { $0.type == config.documentType } ?? Self.documentTypeOptions[0]
    }

    // MARK: - Capture Vision

    let dce = CameraEnhancer()
    let cameraView = CameraView()
    let cvr = CaptureVisionRouter()
    private let imageProcessor = ImageProcessor()
    private let identityProcessor = IdentityProcessor()

    @objc public var config: MRZScannerConfig = .init()
    @objc public var onScannedResult: ((MRZScanResult) -> Void)?

    // MARK: - Scan State

    private var scaledColourImageUnit: ScaledColourImageUnit?
    private var localizedTextLinesUnit: LocalizedTextLinesUnit?
    private var recognizedTextLinesUnit: RecognizedTextLinesUnit?
    private var detectedQuadsUnit: DetectedQuadsUnit?
    private var deskewedImageUnit: DeskewedImageUnit?
    private var returnMRZResult: MRZScanResult?
    private var switchTemplateName: String?
    private var isMrzScanned: Bool = false
    private var didInitSettings: Bool = false
    private var didDeliver: Bool = false
    var portraitTimeoutTimer: Timer?

    /// On-screen flag, so a permission prompt answered after dismissal cannot start the camera.
    var isAppeared: Bool = false
    /// A denial seen before the view joins the window; `viewDidAppear` presents the alert instead.
    var pendingPermissionDenial: AVAuthorizationStatus?

    // MARK: - Views

    /// Framework bundle holding the assets; literal type so an ObjC subclass still resolves here.
    lazy var bundle = Bundle(for: MRZScannerViewController.self)
    lazy var flipOriginalImage = image(named: "flipOriginal")
    lazy var flipAfterImage = image(named: "flipAfter")

    lazy var closeButton: UIButton = createSVGButton(named: "close", label: "Close")
    lazy var torchButton: UIButton = createSVGButton(named: "torchOff", selectedName: "torchOn", label: "Torch")
    lazy var switchButton: UIButton = createSVGButton(named: "switchCamera", label: "Flip camera")
    lazy var beepButton: UIButton = createSVGButton(named: "beepOff", selectedName: "beepOn", label: "Beep")
    lazy var vibrateButton: UIButton = createSVGButton(named: "vibrateOff", selectedName: "vibrateOn", label: "Vibrate")

    lazy var guideBorder: UIView = makeGuideBorder()
    lazy var guideText: UIImageView = makeGuideText()
    lazy var flipPromptImage: UIImageView = makeOverlayImageView(named: "flipOriginal")
    lazy var scannerSpinner: UIImageView = makeOverlayImageView(named: "scannerSpinner")
    lazy var guideLabel: UILabel = makePromptLabel(text: "Scan the MRZ side first", lineSpacing: 4)
    lazy var finishPromptLabel: UILabel = makeFinishPromptLabel()
    lazy var stackView: UIStackView = makeButtonStack()
    lazy var separator: UIView = makeSeparator()
    let bottomMenu = SegmentPickerView()

    var guideHeightConstraint: NSLayoutConstraint?
    var guideWidthConstraint: NSLayoutConstraint?

    // MARK: - Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "MRZ Scanner"
        view.backgroundColor = .black
        setupLicense()
        setupDCV()
        setupUI()
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.verticalSizeClass != previousTraitCollection?.verticalSizeClass else { return }
        updateGuideConstraint()
        applyScanRegionToDCE()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        isMrzScanned = false
        didDeliver = false
        isAppeared = true
        // Reset on the way in: doing it on the way out undid the success state mid-dismissal.
        setGuideFrame(with: .original)
        startCaptureIfAuthorized()
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let status = pendingPermissionDenial {
            pendingPermissionDenial = nil
            presentCameraPermissionAlert(status)
        }
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isAppeared = false
        pendingPermissionDenial = nil
        stop()
        cancelPortraitTimeout()
        finishPromptLabel.isHidden = true
        // Only the flip prompt goes here; the rest resets in viewWillAppear, so the exit keeps its state.
        stopFlipAnimation()
        torchButton.isSelected = false
        returnMRZResult = nil
        stopScannerSpinner()
        releaseIntermediateUnits()
    }

    /// Frees the last frame's full-resolution buffers; main thread after `stop()`, so no race.
    private func releaseIntermediateUnits() {
        scaledColourImageUnit = nil
        localizedTextLinesUnit = nil
        recognizedTextLinesUnit = nil
        detectedQuadsUnit = nil
        deskewedImageUnit = nil
    }
}

// MARK: - Capture Control
extension MRZScannerViewController {

    private func setupDCV() {
        dce.cameraView = cameraView
        cameraView.scanRegionMaskVisible = false
        try? cvr.setInput(dce)
        cvr.addResultReceiver(self)

        let filter = MultiFrameResultCrossFilter()
        filter.enableResultCrossVerification([.textLine, .detectedQuad], isEnabled: true)
        let criteria = CrossVerificationCriteria()
        criteria.frameWindow = 5
        criteria.minConsistentFrames = 2
        filter.setResultCrossVerificationCriteria(criteria, resultItemTypes: .detectedQuad)
        cvr.addResultFilter(filter)

        cvr.getIntermediateResultManager().addResultReceiver(self)
        cameraView.getAllDrawingLayers().forEach { $0.visible = false }
    }

    /// Parsed once per instance; this re-read and re-parsed JSON from disk on every appearance.
    private func initSettingsIfNeeded() throws {
        guard !didInitSettings else { return }
        if let mrzPath = bundle.path(forResource: "mrz-mobile", ofType: "json") {
            try? cvr.initSettingsFromFile(mrzPath)
        }
        if let path = config.templateFile {
            // An inline JSON template is passed by value; anything else is a file path.
            if path.hasPrefix("{") || path.hasPrefix("[") {
                try cvr.initSettings(path)
            } else {
                try cvr.initSettingsFromFile(path)
            }
        }
        didInitSettings = true // only on success, so a failed parse retries next appearance
    }

    func startCapture() {
        dce.open()
        applyScanRegionToDCE()
        do {
            try initSettingsIfNeeded()
        } catch {
            reportException(error)
            return
        }
        // A custom template file replaces the bundled ones; else the selector outranks the config.
        let name = config.templateFile != nil ? "" : (switchTemplateName ?? selectedOption.template)
        cvr.startCapturing(name) { [weak self] isSuccess, error in
            if !isSuccess { self?.reportException(error) }
        }
    }

    func stop() {
        cvr.stopCapturing()
        dce.close()
        dce.clearBuffer()
    }

    private func feedback() {
        if beepButton.isSelected { Feedback.beep() }
        if vibrateButton.isSelected { Feedback.vibrate() }
    }

    private func reportException(_ error: (any Error)?) {
        let nsError = error.map { $0 as NSError }
        onScannedResult?(.init(resultStatus: .exception, errorCode: nsError?.code ?? -1,
                               errorString: nsError?.localizedDescription ?? "Unknown error"))
    }

    /// One delivery per appearance, so a queued success animation cannot fire after Close.
    func deliver(_ result: MRZScanResult) {
        guard !didDeliver else { return }
        didDeliver = true
        onScannedResult?(result)
    }
}

// MARK: - Button Actions
extension MRZScannerViewController {

    @objc func onCloseButtonTouchUp() {
        stop()
        deliver(.init(resultStatus: .canceled))
    }

    @objc func onFinishPromptTapped() {
        guard let result = returnMRZResult else { return }
        cancelPortraitTimeout()
        finishPromptLabel.isHidden = true
        stop()
        deliver(result)
    }

    @objc func onTorchButtonTouchUp(_ sender: UIButton) {
        sender.isSelected.toggle()
        if sender.isSelected { dce.turnOnTorch() } else { dce.turnOffTorch() }
    }

    @objc func onSwitchButtonTouchUp(_ sender: UIButton) {
        sender.isSelected.toggle()
        dce.selectCamera(with: sender.isSelected ? .front : .backDualWideAuto, completion: nil)
    }

    /// Feedback reads `isSelected` directly, so toggling is all either button has to do.
    @objc func onToggleButtonTouchUp(_ sender: UIButton) {
        sender.isSelected.toggle()
    }

    func handleSelection(mode: String) {
        guard let option = Self.documentTypeOptions.first(where: { $0.label == mode }) else { return }
        try? cvr.switchCapturingTemplate(option.template)
        switchTemplateName = option.template
    }
}

// MARK: - CapturedResultReceiver
extension MRZScannerViewController: CapturedResultReceiver {

    public func onCapturedResultReceived(_ result: CapturedResult) {
        let quadItem = result.processedDocumentResult?.detectedQuadResultItems?
            .first { $0.crossVerificationStatus != .failed }
        if config.returnDocumentImage && quadItem == nil { return }

        let photoLocation = precisePortraitLocation()
        let mrzData = (result.parsedResult?.items?.first).flatMap { MRZData($0) }
        let hasMRZ = mrzData != nil
        let currentResult = MRZScanResult(resultStatus: .finished, data: mrzData)

        populateImages(result: currentResult, hasMRZ: hasMRZ, quadItem: quadItem,
                       photoLocation: photoLocation) { [weak self] in
            self?.cvr.getIntermediateResultManager().getOriginalImage(result.originalImageHashId)
        }

        if hasMRZ {
            handleMRZScanned(currentResult)
        } else {
            handlePortraitScanned(currentResult)
        }
    }
}

// MARK: - Image Extraction
extension MRZScannerViewController {

    private func isPortraitValid(quad: Quadrilateral, within docRegion: Quadrilateral) -> Bool {
        guard quad.area > 0 else { return false }
        return (docRegion.area / quad.area >= 3)
            && quad.points.allSatisfy({ docRegion.contains($0.cgPointValue) })
    }

    private func precisePortraitLocation() -> Quadrilateral? {
        guard config.returnPortraitImage,
              let scaledUnit = scaledColourImageUnit,
              let localizedUnit = localizedTextLinesUnit,
              let textLinesUnit = recognizedTextLinesUnit,
              let quadsUnit = detectedQuadsUnit,
              quadsUnit.getCount() > 0,
              let imageUnit = deskewedImageUnit,
              let elements = localizedUnit.getAuxiliaryRegionElements() else { return nil }

        // No high-confidence portrait zone: skip the identity processor rather than return a vague one.
        guard elements.contains(where: { $0.getName() == "PortraitZone" && $0.getConfidence() >= 60 }) else {
            return nil
        }

        return identityProcessor.findPortraitZone(
            scaledUnit,
            localizedTextLinesUnit: localizedUnit,
            recognizedTextLinesUnit: textLinesUnit,
            detectedQuadsUnit: quadsUnit,
            deskewedImageUnit: imageUnit
        )
    }

    /// The MRZ side fills the primary slots, the opposite side the secondary ones.
    private func populateImages(result: MRZScanResult, hasMRZ: Bool, quadItem: DetectedQuadResultItem?,
                                photoLocation: Quadrilateral?, imageDataProvider: () -> ImageData?) {
        guard config.returnOriginalImage || config.returnDocumentImage || config.returnPortraitImage,
              let imageData = imageDataProvider() else { return }

        if config.returnOriginalImage {
            let slot = hasMRZ ? \MRZScanResult.primaryOriginalImage : \MRZScanResult.secondaryOriginalImage
            result[keyPath: slot] = imageData
        }

        if config.returnDocumentImage, let quad = quadItem?.location {
            let slot = hasMRZ ? \MRZScanResult.primaryDocumentImage : \MRZScanResult.secondaryDocumentImage
            result[keyPath: slot] = try? imageProcessor.cropAndDeskewImage(imageData, quad: quad)
        }

        if config.returnPortraitImage, let quad = photoLocation, let docRegion = quadItem?.location,
           isPortraitValid(quad: quad, within: docRegion) {
            result.portraitImage = try? imageProcessor.cropAndDeskewImage(imageData, quad: quad)
        }
    }
}

// MARK: - Result Delivery
extension MRZScannerViewController {

    /// Runs the success animation for `mode`; the 0.3s gap lets it land before dismissal.
    private func showSuccessThenDeliver(_ mode: GuideFrameMode, result: MRZScanResult) {
        setGuideFrame(with: mode) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard self?.isAppeared == true else { return }
                self?.deliver(result)
            }
        }
    }

    private func handleMRZScanned(_ currentResult: MRZScanResult) {
        let isNewResult = returnMRZResult == nil
            || returnMRZResult?.data?.mrzText != currentResult.data?.mrzText
        returnMRZResult = currentResult

        let isPassport = currentResult.data?.documentType == "MRTD_TD3_PASSPORT"
        let hasPortrait = currentResult.portraitImage != nil

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isMrzScanned = true
            self.stopScannerSpinner()
            if isNewResult { self.feedback() }

            // Each path stops capture itself — main here, capture thread for portrait; do not collapse.
            if hasPortrait {
                self.stop()
                self.showSuccessThenDeliver(.scannedMRZWithPortrait, result: currentResult)
            } else if !self.config.returnPortraitImage {
                self.stop()
                self.showSuccessThenDeliver(.scannedMRZ, result: currentResult)
            } else if isNewResult && isPassport {
                // Single-sided: just wait out the portrait timeout.
                self.setGuideFrame(with: .scannedMRZWithoutPortrait) { self.startPortraitTimeout() }
            } else if isNewResult {
                // Double-sided: prompt the flip, then let it play a second before the timeout starts.
                self.setGuideFrame(with: .scannedOneSide) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                        guard self?.isAppeared == true else { return }
                        self?.startPortraitTimeout()
                    }
                }
            }
        }
    }

    private func handlePortraitScanned(_ currentResult: MRZScanResult) {
        // MRZScanResult is a class, so merging into `pending` merges into returnMRZResult.
        guard let pending = returnMRZResult,
              pending.data?.documentType != "MRTD_TD3_PASSPORT" else { return }
        if config.returnPortraitImage && currentResult.portraitImage == nil { return }

        pending.portraitImage = currentResult.portraitImage
        pending.secondaryOriginalImage = currentResult.secondaryOriginalImage
        pending.secondaryDocumentImage = currentResult.secondaryDocumentImage

        stop()

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.feedback()
            self.cancelPortraitTimeout()
            self.finishPromptLabel.isHidden = true
            self.showSuccessThenDeliver(.scannedBothSides, result: pending)
        }
    }
}

// MARK: - IntermediateResultReceiver
extension MRZScannerViewController: IntermediateResultReceiver {

    public func onScaledColourImageUnitReceived(_ unit: ScaledColourImageUnit, info: IntermediateResultExtraInfo) {
        scaledColourImageUnit = unit
    }

    public func onLocalizedTextLinesReceived(_ unit: LocalizedTextLinesUnit, info: IntermediateResultExtraInfo) {
        localizedTextLinesUnit = unit
        // Localized text lines mean OCR is working; suppressed after MRZ so it won't fight the flip icon.
        let hasTextLines = unit.getCount() > 0
        DispatchQueue.main.async { [weak self] in
            guard let self = self, !self.isMrzScanned else { return }
            if hasTextLines { self.startScannerSpinner() } else { self.stopScannerSpinner() }
        }
    }

    public func onRecognizedTextLinesReceived(_ unit: RecognizedTextLinesUnit, info: IntermediateResultExtraInfo) {
        recognizedTextLinesUnit = unit
    }

    public func onDetectedQuadsReceived(_ unit: DetectedQuadsUnit, info: IntermediateResultExtraInfo) {
        detectedQuadsUnit = unit
    }

    public func onDeskewedImageReceived(_ unit: DeskewedImageUnit, info: IntermediateResultExtraInfo) {
        deskewedImageUnit = unit
    }
}

// MARK: - LicenseVerificationListener
extension MRZScannerViewController: LicenseVerificationListener {

    private func setupLicense() {
        LicenseManager.initLicense(config.license, verificationDelegate: self)
    }

    public func onLicenseVerified(_ isSuccess: Bool, error: (any Error)?) {
        guard !isSuccess else { return }
        reportException(error)
    }
}
