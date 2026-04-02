//
//  MRZScannerViewController.swift
//  DynamsoftMRZScannerBundle
//
//  Copyright © Dynamsoft Corporation.  All rights reserved.
//

import DynamsoftCaptureVisionBundle

@objc(DSMRZScannerViewController)
public class MRZScannerViewController: UIViewController {
    
    enum GuideFrameMode {
    case original
    case scannedOneSide
    case scannedBothSides
    case scannedMRZWithoutPortrait
    case scannedMRZWithPortrait
    }
    
    let dce = CameraEnhancer()
    let cameraView = CameraView()
    let cvr = CaptureVisionRouter()
    @objc public var config: MRZScannerConfig = .init()
    @objc public var onScannedResult: ((MRZScanResult) -> Void)?
    
    private var scaledColourImageUnit: ScaledColourImageUnit?
    private var localizedTextLinesUnit: LocalizedTextLinesUnit?
    private var recognizedTextLinesUnit: RecognizedTextLinesUnit?
    private var detectedQuadsUnit: DetectedQuadsUnit?
    private var deskewedImageUnit: DeskewedImageUnit?
    private var returnMRZResult: MRZScanResult?
    private let imageProcessor = ImageProcessor()
    private var portraitTimeoutTimer: Timer?
    private var isWaitingForPortrait: Bool = false
    private var switchTemplateName: String?
    
    private let bottomMenu = SegmentPickerView()
    
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

        guard traitCollection.verticalSizeClass != previousTraitCollection?.verticalSizeClass else {
            return
        }

        updateGuideConstraint()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dce.open()
        let mrzPath = Bundle(for: MRZScannerViewController.self).path(forResource: "mrz-mobile", ofType: "json")
        if let path = mrzPath {
            try? cvr.initSettingsFromFile(path)
        }
        var name: String
        switch config.documentType {
        case .all:
            name = "ReadPassportAndId"
        case .id:
            name = "ReadId"
        case .passport:
            name = "ReadPassport"
        }
        if let str = switchTemplateName {
            name = str
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
        cancelPortraitTimeout()
        finishPromptLabel.isHidden = true
        setGuideFrame(with: .original)
        torchButton.isSelected = false
        returnMRZResult = nil
    }
    
    lazy var closeButton: UIButton = {
        let button = createSVGButton(named: "close")
        return button
    }()
    
    private var guideHeightConstraint: NSLayoutConstraint?
    private var guideWidthConstraint: NSLayoutConstraint?
    
    lazy var guideBorder: UIView = {
        let guideView = UIView()
        guideView.translatesAutoresizingMaskIntoConstraints = false
        guideView.backgroundColor = .clear
        guideView.layer.borderColor = UIColor.white.cgColor
        guideView.layer.borderWidth = 2
        guideView.layer.cornerRadius = 16
        guideView.layer.masksToBounds = true
        return guideView
    }()
    
    lazy var guideText: UIImageView = {
        let bundle = Bundle(for: type(of: self))
        let imageView = UIImageView(image: UIImage(named: "guideText", in: bundle, compatibleWith: nil))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        return imageView
    }()
    
    lazy var guideLabel: UILabel = {
        let label = PaddingLabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        label.layer.cornerRadius = 8
        label.layer.masksToBounds = true
        label.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        label.numberOfLines = 0
        label.attributedText = NSMutableAttributedString(string: "Scan the MRZ side first", attributes: [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.white,
            .paragraphStyle: {
                let style = NSMutableParagraphStyle()
                style.alignment = .center
                style.lineSpacing = 4
                return style
            }()
        ])
        return label
    }()
    
    lazy var torchButton: UIButton = {
        let button = createSVGButton(named: "torchOff", selectedName: "torchOn")
        return button
    }()
    
    lazy var switchButton: UIButton = {
        let button = createSVGButton(named: "switchCamera")
        return button
    }()
    
    lazy var beepButton: UIButton = {
        let button = createSVGButton(named: "beepOff", selectedName: "beepOn")
        return button
    }()
    
    lazy var vibrateButton: UIButton = {
        let button = createSVGButton(named: "vibrateOff", selectedName: "vibrateOn")
        return button
    }()
    
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private func createSVGButton(named: String, selectedName: String? = nil) -> UIButton {
        let bundle = Bundle(for: type(of: self))
        let btn = UIButton(type: .custom)
        
        if let image = UIImage(named: named, in: bundle, compatibleWith: nil) {
            btn.setImage(image.withRenderingMode(.alwaysOriginal), for: .normal)
        }
        if let name = selectedName, let image = UIImage(named: name, in: bundle, compatibleWith: nil) {
            btn.setImage(image.withRenderingMode(.alwaysOriginal), for: .selected)
        }
        
        btn.translatesAutoresizingMaskIntoConstraints = false
        
        let widthConstraint = btn.widthAnchor.constraint(equalToConstant: 40)
        let heightConstraint = btn.heightAnchor.constraint(equalToConstant: 40)
        widthConstraint.priority = UILayoutPriority(999)
        heightConstraint.priority = UILayoutPriority(999)
        NSLayoutConstraint.activate([widthConstraint, heightConstraint])
        
        btn.contentHorizontalAlignment = .fill
        btn.contentVerticalAlignment = .fill
        btn.imageView?.contentMode = .center
        
        return btn
    }

    private let separator: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var finishPromptLabel: UILabel = {
        let label = PaddingLabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        label.layer.cornerRadius = 8
        label.layer.masksToBounds = true
        label.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        label.numberOfLines = 0
        label.isUserInteractionEnabled = true
        label.isHidden = true
        label.attributedText = NSMutableAttributedString(string: "Continue scanning or tap to finish →", attributes: [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.white,
            .paragraphStyle: {
                let style = NSMutableParagraphStyle()
                style.alignment = .center
                return style
            }()
        ])
        return label
    }()
}

// MARK: - Setup Methods
extension MRZScannerViewController {
    private func setupDCV() {
        dce.cameraView = cameraView
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
        cameraView.getAllDrawingLayers().forEach { layer in
            layer.visible = false
        }
    }
    
    private func setupUI() {
        let safeArea = view.safeAreaLayoutGuide
        
        cameraView.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(cameraView, at: 0)
        
        // Top Menu
        let topMenu = UIView()
        topMenu.translatesAutoresizingMaskIntoConstraints = false
        topMenu.backgroundColor = .black
        view.addSubview(topMenu)
        
        closeButton.isHidden = !config.isCloseButtonVisible
        topMenu.addSubview(closeButton)
        
        topMenu.addSubview(stackView)
        [torchButton, switchButton, separator, beepButton, vibrateButton].forEach { stackView.addArrangedSubview($0) }
        
        torchButton.isHidden = !config.isTorchButtonVisible
        switchButton.isHidden = !config.isCameraToggleButtonVisible
        beepButton.isHidden = !config.isBeepButtonVisible
        vibrateButton.isHidden = !config.isVibrateButtonVisible
        separator.isHidden = (torchButton.isHidden && switchButton.isHidden) || (beepButton.isHidden && vibrateButton.isHidden)
        
        beepButton.isSelected = config.isBeepEnabled
        vibrateButton.isSelected = config.isVibrateEnabled
        
        let topMenuVisible = config.isCloseButtonVisible || config.isCameraToggleButtonVisible || config.isTorchButtonVisible || config.isBeepButtonVisible || config.isVibrateButtonVisible
        topMenu.isHidden = !topMenuVisible
        let topConstant = topMenuVisible ? 56.0 : 0.0
        
        NSLayoutConstraint.activate([
            topMenu.topAnchor.constraint(equalTo: view.topAnchor),
            topMenu.bottomAnchor.constraint(equalTo: safeArea.topAnchor, constant: topConstant),
            topMenu.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topMenu.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            closeButton.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 8),
            closeButton.bottomAnchor.constraint(equalTo: topMenu.bottomAnchor, constant: -8),
            
            stackView.bottomAnchor.constraint(equalTo: topMenu.bottomAnchor, constant: -8),
            stackView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -8),
            
            separator.widthAnchor.constraint(equalToConstant: 1),
            separator.heightAnchor.constraint(equalToConstant: 16)
        ])
        
        // Bottom Menu
        let safeBottom = UIView()
        safeBottom.translatesAutoresizingMaskIntoConstraints = false
        safeBottom.backgroundColor = .black
        view.addSubview(safeBottom)
        
        NSLayoutConstraint.activate([
            safeBottom.topAnchor.constraint(equalTo: safeArea.bottomAnchor),
            safeBottom.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            safeBottom.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            safeBottom.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        var option = "Both"
        switch config.documentType {
        case .all:
            option = "Both"
        case .id:
            option = "ID"
        case .passport:
            option = "Passport"
        }
        bottomMenu.setSelectedOption(option)
        bottomMenu.backgroundColor = .black
        bottomMenu.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomMenu)
        
        bottomMenu.isHidden = !config.isFormatSelectorVisible
        let bottomConstant = config.isFormatSelectorVisible ? 64.0 : 0.0
        
        NSLayoutConstraint.activate([
            bottomMenu.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomMenu.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomMenu.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor),
            bottomMenu.heightAnchor.constraint(equalToConstant: bottomConstant)
        ])
        
        // Camera View Constraints
        NSLayoutConstraint.activate([
            cameraView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            cameraView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            cameraView.topAnchor.constraint(equalTo: topMenu.bottomAnchor),
            cameraView.bottomAnchor.constraint(equalTo: bottomMenu.topAnchor)
        ])
        
        // Guide Frame
        guideBorder.addSubview(guideText)
        NSLayoutConstraint.activate([
            guideText.centerXAnchor.constraint(equalTo: guideBorder.centerXAnchor),
            guideText.bottomAnchor.constraint(equalTo: guideBorder.bottomAnchor, constant: -8),
            guideText.widthAnchor.constraint(equalTo: guideBorder.widthAnchor, multiplier: 0.95),
        ])
        
        guideBorder.isHidden = !config.isGuideFrameVisible
        view.addSubview(guideBorder)
        
        NSLayoutConstraint.activate([
            guideBorder.centerXAnchor.constraint(equalTo: cameraView.centerXAnchor),
            guideBorder.centerYAnchor.constraint(equalTo: cameraView.centerYAnchor),
        ])
        updateGuideConstraint()
        
        guideLabel.isHidden = !config.isGuideFrameVisible
        view.addSubview(guideLabel)
        NSLayoutConstraint.activate([
            guideLabel.centerXAnchor.constraint(equalTo: guideBorder.centerXAnchor),
            guideLabel.bottomAnchor.constraint(equalTo: guideBorder.topAnchor, constant: -16),
        ])
        
        // Finish Prompt Label (tap to finish)
        view.addSubview(finishPromptLabel)
        NSLayoutConstraint.activate([
            finishPromptLabel.centerXAnchor.constraint(equalTo: cameraView.centerXAnchor),
//            finishPromptLabel.centerYAnchor.constraint(equalTo: cameraView.centerYAnchor),
            finishPromptLabel.topAnchor.constraint(equalTo: guideBorder.bottomAnchor, constant: 16)
        ])
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onFinishPromptTapped))
        finishPromptLabel.addGestureRecognizer(tapGesture)
        
        // Selector Actions
        closeButton.addTarget(self, action: #selector(onCloseButtonTouchUp), for: .touchUpInside)
        torchButton.addTarget(self, action: #selector(onTorchButtonTouchUp), for: .touchUpInside)
        switchButton.addTarget(self, action: #selector(onSwitchButtonTouchUp), for: .touchUpInside)
        beepButton.addTarget(self, action: #selector(onBeepButtonTouchUp), for: .touchUpInside)
        vibrateButton.addTarget(self, action: #selector(onVibrateButtonTouchUp), for: .touchUpInside)
        
        bottomMenu.onChanged = { [weak self] selectedMode in
            self?.handleSelection(mode: selectedMode)
        }
    }
    
    private func feedback() -> Void {
        if beepButton.isSelected {
            Feedback.beep()
        }
        if vibrateButton.isSelected {
            Feedback.vibrate()
        }
    }
    
    private func stop() {
        cvr.stopCapturing()
        dce.close()
        dce.clearBuffer()
    }
}

// MARK: - Button Actions
extension MRZScannerViewController {
    @objc func onCloseButtonTouchUp() {
        stop()
        onScannedResult?(.init(resultStatus: .canceled))
    }
    
    @objc func onFinishPromptTapped() {
        guard let result = returnMRZResult else { return }
        
        cancelPortraitTimeout()
        finishPromptLabel.isHidden = true
        stop()
        
        onScannedResult?(result)
    }
    
    @objc func onTorchButtonTouchUp(_ sender: UIButton) {
        sender.isSelected.toggle()
        if sender.isSelected {
            dce.turnOnTorch()
        } else {
            dce.turnOffTorch()
        }
    }
    
    @objc func onSwitchButtonTouchUp(_ sender: UIButton) {
        sender.isSelected.toggle()
        if sender.isSelected {
            dce.selectCamera(with: .front, completion: nil)
        } else {
            dce.selectCamera(with: .backDualWideAuto, completion: nil)
        }
    }
    
    @objc func onBeepButtonTouchUp(_ sender: UIButton) {
        sender.isSelected.toggle()
    }
    
    @objc func onVibrateButtonTouchUp(_ sender: UIButton) {
        sender.isSelected.toggle()
    }
    
    private func handleSelection(mode: String) {
        switch mode {
        case "ID":
            try? cvr.switchCapturingTemplate("ReadId")
            switchTemplateName = "ReadId"
        case "Both":
            try? cvr.switchCapturingTemplate("ReadPassportAndId")
            switchTemplateName = "ReadPassportAndId"
        case "Passport":
            try? cvr.switchCapturingTemplate("ReadPassport")
            switchTemplateName = "ReadPassport"
        default:
            break
        }
    }
}

// MARK: - Guide Frame Logic
extension MRZScannerViewController {
    
    private func updateGuideConstraint() {
        guideHeightConstraint?.isActive = false
        guideWidthConstraint?.isActive = false
        
        let isPortrait = traitCollection.verticalSizeClass == .regular
        let heightMultiplier: CGFloat = isPortrait ? 0.35 : 0.8
        let widthMultiplier: CGFloat = isPortrait ? 0.9 : 0.6
        
        guideHeightConstraint = guideBorder.heightAnchor.constraint(
            equalTo: cameraView.heightAnchor,
            multiplier: heightMultiplier
        )
        
        guideWidthConstraint = guideBorder.widthAnchor.constraint(
            equalTo: cameraView.widthAnchor,
            multiplier: widthMultiplier
        )
        
        guideWidthConstraint?.isActive = true
        guideHeightConstraint?.isActive = true
    }
    
    func setGuideFrame(with mode: GuideFrameMode, completion:(() -> Void)? = nil) {
        let white = UIColor.white.cgColor
        
        switch mode {
        case .original:
            guideBorder.layer.borderColor = white
            guideText.isHidden = false
            setGuideLabel(highlightedText: nil, normalText: "Scan the MRZ side first")
            bottomMenu.isEnabled = true
            completion?()
        case .scannedOneSide:
            performScanAnimation(
                highlightedText: "MRZ scanned ✓",
                normalText: "Flip and scan the other side",
                completion: completion
            )
            bottomMenu.isEnabled = false
        case .scannedBothSides:
            performScanAnimation(
                highlightedText: "MRZ scanned ✓\nBoth sides scanned ✓",
                normalText: nil,
                completion: completion
            )
            bottomMenu.isEnabled = true
        case .scannedMRZWithoutPortrait:
            performScanAnimation(
                highlightedText: "MRZ scanned ✓",
                normalText: "Finding portrait...",
                completion: completion
            )
            bottomMenu.isEnabled = true
        case .scannedMRZWithPortrait:
            performScanAnimation(
                highlightedText: "MRZ scanned ✓\nPortrait scanned ✓",
                normalText: nil,
                completion: completion
            )
            bottomMenu.isEnabled = true
        }
    }
    
    private func performScanAnimation(
        highlightedText: String?,
        normalText: String?,
        hideGuideText: Bool = true,
        completion: (() -> Void)?
    ) {
        let green = UIColor.systemGreen.cgColor
        let white = UIColor.white.cgColor
        
        guideBorder.layer.borderColor = green
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            guard let self = self else { return }
            
            UIView.transition(
                with: self.guideLabel,
                duration: 0.3,
                options: [.transitionCrossDissolve],
                animations: {
                    self.setGuideLabel(
                        highlightedText: highlightedText,
                        normalText: normalText
                    )
                    self.guideText.isHidden = hideGuideText
                },
                completion: { _ in
                    UIView.animate(
                        withDuration: 0.3,
                        delay: 0,
                        options: [.curveEaseOut],
                        animations: {
                            self.guideBorder.layer.borderColor = white
                        },
                        completion: { _ in
                            completion?()
                        }
                    )
                }
            )
        }
    }
    
    func setGuideLabel(
        highlightedText: String?,
        normalText: String?
    ) {
        var parts: [String] = []

        if let highlighted = highlightedText, !highlighted.isEmpty {
            parts.append(highlighted)
        }

        if let normal = normalText, !normal.isEmpty {
            parts.append(normal)
        }

        let fullText = parts.joined(separator: "\n")
        guard !fullText.isEmpty else {
            guideLabel.attributedText = nil
            return
        }

        let attributed = NSMutableAttributedString(
            string: fullText,
            attributes: [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.white
            ]
        )

        if let highlighted = highlightedText, !highlighted.isEmpty {
            let range = (fullText as NSString).range(of: highlighted)
            if range.location != NSNotFound {
                attributed.addAttributes(
                    [
                        .foregroundColor: UIColor.systemOrange,
                        .font: UIFont.boldSystemFont(ofSize: 14)
                    ],
                    range: range
                )
            }
        }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineSpacing = 4
        attributed.addAttribute(
            .paragraphStyle,
            value: paragraphStyle,
            range: NSRange(location: 0, length: attributed.length)
        )

        guideLabel.attributedText = attributed
    }
    
    private func startPortraitTimeout() {
        cancelPortraitTimeout()
        isWaitingForPortrait = true
        portraitTimeoutTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            self?.onPortraitTimeout()
        }
    }
    
    private func cancelPortraitTimeout() {
        portraitTimeoutTimer?.invalidate()
        portraitTimeoutTimer = nil
        isWaitingForPortrait = false
    }
    
    private func onPortraitTimeout() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isWaitingForPortrait = false
            self.finishPromptLabel.isHidden = false
            setGuideLabel(highlightedText: "MRZ scanned ✓", normalText: "No portrait detected")
        }
    }
}

// MARK: - CapturedResultReceiver
extension MRZScannerViewController: CapturedResultReceiver {
    
    public func onCapturedResultReceived(_ result: CapturedResult) {
        let quadItem = result.processedDocumentResult?.detectedQuadResultItems?.first { $0.crossVerificationStatus != .failed }
        
        if config.returnDocumentImage && quadItem == nil { return }

        let precisePhotoLocation = precisePortraitLocation()
        
        // mrz data
        let mrzData = convertToMRZData(item: result.parsedResult?.items?.first)
        let hasMRZ = mrzData != nil
        let currentResult = MRZScanResult(resultStatus: .finished, data: mrzData)
        
        // get image data provider
        let getImageData: () -> ImageData? = { [weak self] in
            self?.cvr.getIntermediateResultManager().getOriginalImage(result.originalImageHashId)
        }
        
        populateImages(
            result: currentResult,
            hasMRZ: hasMRZ,
            quadItem: quadItem,
            photoLocation: precisePhotoLocation,
            imageDataProvider: getImageData
        )
        
        if hasMRZ {
            handleMRZScanned(currentResult)
        } else {
            handlePortraitScanned(currentResult)
        }
    }
}

// MARK: - MRZ Scanning Logic
extension MRZScannerViewController {
    
    private func isPortraitValid(quad: Quadrilateral, within docRegion: Quadrilateral) -> Bool {
        guard quad.area > 0 else { return false }
        return (docRegion.area / quad.area >= 3) &&
               quad.points.allSatisfy({ docRegion.contains($0.cgPointValue) })
    }
    
    private func precisePortraitLocation() -> Quadrilateral? {
        guard config.returnPortraitImage,
              let scaledUnit = scaledColourImageUnit,
              let localizedUnit = localizedTextLinesUnit,
              let textLinesUnit = recognizedTextLinesUnit,
              let quadsUnit = detectedQuadsUnit,
              quadsUnit.getCount() > 0,
              let imageUnit = deskewedImageUnit,
              let elements = localizedUnit.getAuxiliaryRegionElements() else {
            return nil
        }
        
        var isValid = false
        for element in elements {
            if element.getName() == "PortraitZone" && element.getConfidence() >= 60 {
                isValid = true
                break
            }
        }
        guard isValid else {
            return nil
        }
        
        return IdentityProcessor().findPortraitZone(
            scaledUnit,
            localizedTextLinesUnit: localizedUnit,
            recognizedTextLinesUnit: textLinesUnit,
            detectedQuadsUnit: quadsUnit,
            deskewedImageUnit: imageUnit
        )
    }
    
    private func populateImages(
        result: MRZScanResult,
        hasMRZ: Bool,
        quadItem: DetectedQuadResultItem?,
        photoLocation: Quadrilateral?,
        imageDataProvider: () -> ImageData?
    ) {

        guard config.returnOriginalImage || config.returnDocumentImage || config.returnPortraitImage else { return }
        guard let imageData = imageDataProvider() else { return }
        
        if config.returnOriginalImage {
            if hasMRZ {
                result.primaryOriginalImage = imageData
            } else {
                result.secondaryOriginalImage = imageData
            }
        }
        
        if config.returnDocumentImage, let quad = quadItem?.location {
            let image = try? imageProcessor.cropAndDeskewImage(imageData, quad: quad)
            if hasMRZ {
                result.primaryDocumentImage = image
            } else {
                result.secondaryDocumentImage = image
            }
        }
        
        if config.returnPortraitImage,
            let quad = photoLocation,
            let docRegion = quadItem?.location,
            isPortraitValid(quad: quad, within: docRegion) {
            result.portraitImage = try? imageProcessor.cropAndDeskewImage(imageData, quad: quad)
        }
    }
    
    private func handleMRZScanned(_ currentResult: MRZScanResult) {
        
        let isNewResult = returnMRZResult == nil || returnMRZResult?.data?.mrzText != currentResult.data?.mrzText
        returnMRZResult = currentResult
        
        let documentType = returnMRZResult?.data?.documentType ?? ""
        let isPassport = documentType == "MRTD_TD3_PASSPORT"
        let hasPortrait = returnMRZResult?.portraitImage != nil
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if isPassport {
                if isNewResult {
                    self.feedback()
                }
                // Passport: single side logic
                if hasPortrait || !self.config.returnPortraitImage {
                    // Got portrait or don't need portrait, finish immediately
                    self.stop()
                    self.setGuideFrame(with: .scannedMRZWithPortrait) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                            guard let self = self, let result = self.returnMRZResult else { return }
                            self.onScannedResult?(result)
                        }
                    }
                } else {
                    // No portrait yet, start 5s timeout
                    if isNewResult {
                        self.setGuideFrame(with: .scannedMRZWithoutPortrait) {
                            self.startPortraitTimeout()
                        }
                    }
                }
            } else {
                // ID: double side logic - prompt to flip
                if isNewResult {
                    self.feedback()
                    self.setGuideFrame(with: .scannedOneSide) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                            guard let self = self else { return }
                            self.startPortraitTimeout()
                        }
                    }
                }
            }
        }
    }
    
    private func handlePortraitScanned(_ currentResult: MRZScanResult) {
        guard let _ = returnMRZResult else { return }
        let documentType = returnMRZResult?.data?.documentType ?? ""
        let isPassport = documentType == "MRTD_TD3_PASSPORT"
        guard !isPassport else { return }
        
        if config.returnPortraitImage && currentResult.portraitImage == nil { return }
        
        returnMRZResult?.portraitImage = currentResult.portraitImage
        returnMRZResult?.secondaryOriginalImage = currentResult.secondaryOriginalImage
        returnMRZResult?.secondaryDocumentImage = currentResult.secondaryDocumentImage
        
        stop()
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.feedback()
            self.cancelPortraitTimeout()
            self.finishPromptLabel.isHidden = true
            self.setGuideFrame(with: .scannedBothSides) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                    guard let self = self, let result = self.returnMRZResult else { return }
                    self.onScannedResult?(result)
                }
            }
        }
    }
}

// MARK: - MRZ Data Conversion
extension MRZScannerViewController {
    private func convertToMRZData(item: ParsedResultItem?) -> MRZData? {
        guard let item = item else { return nil }
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
              let issuingState = parsedFields["issuingState"],
              let nationality = parsedFields["nationality"] else { return nil }
        
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

        let issuingStateRaw = item.getFieldRawValue("issuingState")
        let nationalityRaw = item.getFieldRawValue("nationality")
        
        let personalNumber = parsedFields["personalNumber"]
        let optionalData1 = item.getFieldRawValue("optionalData1")
        let optionalData2 = item.getFieldRawValue("optionalData2")
        
        let mrzData = MRZData(mrzText: mrzText, firstName: firstName, lastName: lastName, sex: sex, age: age, issuingState: issuingState, issuingStateRaw: issuingStateRaw, nationality: nationality, nationalityRaw: nationalityRaw, dateOfBirth: dateOfBirth, dateOfExpire: dateOfExpire, documentType: codeType, documentNumber: documentNumber, personalNumber: personalNumber, optionalData1: optionalData1, optionalData2: optionalData2)
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

// MARK: - Intermediate Result Receiver
extension MRZScannerViewController: IntermediateResultReceiver {
    public func onScaledColourImageUnitReceived(_ unit: ScaledColourImageUnit, info: IntermediateResultExtraInfo) {
        scaledColourImageUnit = unit
    }
    
    public func onLocalizedTextLinesReceived(_ unit: LocalizedTextLinesUnit, info: IntermediateResultExtraInfo) {
        localizedTextLinesUnit = unit
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

// MARK: - License Verification
extension MRZScannerViewController: LicenseVerificationListener {
    
    private func setupLicense() {
        LicenseManager.initLicense(config.license, verificationDelegate: self)
    }
    
    public func onLicenseVerified(_ isSuccess: Bool, error: (any Error)?) {
        if !isSuccess {
            print(error?.localizedDescription ?? "License verification failed")
        }
    }
}
