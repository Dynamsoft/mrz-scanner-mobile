//
//  MRZScannerViewController+UI.swift
//  DynamsoftMRZScannerBundle
//
//  Copyright © Dynamsoft Corporation.  All rights reserved.
//

import UIKit

// MARK: - View Factories
extension MRZScannerViewController {

    /// Images live in the framework bundle's asset catalog, not the app's main bundle.
    func image(named: String) -> UIImage? {
        UIImage(named: named, in: bundle, compatibleWith: nil)
    }

    func createSVGButton(named: String, selectedName: String? = nil, label: String) -> UIButton {
        let btn = UIButton(type: .custom)
        btn.accessibilityLabel = label
        if let image = image(named: named) {
            btn.setImage(image.withRenderingMode(.alwaysOriginal), for: .normal)
        }
        if let selectedName = selectedName, let image = image(named: selectedName) {
            btn.setImage(image.withRenderingMode(.alwaysOriginal), for: .selected)
        }
        btn.translatesAutoresizingMaskIntoConstraints = false
        // 999 so the stack view can compress a button rather than break the layout.
        for constraint in [btn.widthAnchor.constraint(equalToConstant: 40),
                           btn.heightAnchor.constraint(equalToConstant: 40)] {
            constraint.priority = UILayoutPriority(999)
            constraint.isActive = true
        }
        btn.contentHorizontalAlignment = .fill
        btn.contentVerticalAlignment = .fill
        btn.imageView?.contentMode = .center
        return btn
    }

    /// Flip prompt and spinner are built alike: scaled to fit, hidden until the scan state calls.
    func makeOverlayImageView(named: String) -> UIImageView {
        let imageView = UIImageView(image: image(named: named))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        return imageView
    }

    func makeGuideBorder() -> UIView {
        let guideView = UIView()
        guideView.translatesAutoresizingMaskIntoConstraints = false
        guideView.backgroundColor = .clear
        guideView.layer.borderColor = UIColor.white.cgColor
        guideView.layer.borderWidth = 2
        guideView.layer.cornerRadius = 16
        guideView.layer.masksToBounds = true
        return guideView
    }

    func makeGuideText() -> UIImageView {
        let imageView = UIImageView(image: image(named: "guideText"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        return imageView
    }

    func makeButtonStack() -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }

    func makeSeparator() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }

    /// Centred white 14pt prompt copy; `highlighted`, when present, is drawn bold orange.
    func promptText(_ text: String, highlighted: String? = nil, lineSpacing: CGFloat = 0) -> NSAttributedString {
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        style.lineSpacing = lineSpacing
        let attributed = NSMutableAttributedString(string: text, attributes: [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.white,
            .paragraphStyle: style
        ])
        if let highlighted = highlighted, !highlighted.isEmpty {
            let range = (text as NSString).range(of: highlighted)
            if range.location != NSNotFound {
                attributed.addAttributes([.foregroundColor: UIColor.systemOrange,
                                          .font: UIFont.boldSystemFont(ofSize: 14)], range: range)
            }
        }
        return attributed
    }

    /// Both prompt labels share the same rounded translucent chrome.
    func makePromptLabel(text: String, lineSpacing: CGFloat = 0) -> PaddingLabel {
        let label = PaddingLabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        label.layer.cornerRadius = 8
        label.layer.masksToBounds = true
        label.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        label.numberOfLines = 0
        label.attributedText = promptText(text, lineSpacing: lineSpacing)
        return label
    }

    func makeFinishPromptLabel() -> PaddingLabel {
        let label = makePromptLabel(text: "Continue scanning or tap to finish →")
        label.isUserInteractionEnabled = true
        label.isHidden = true
        return label
    }
}

// MARK: - Layout
extension MRZScannerViewController {

    func setupUI() {
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
        [torchButton, switchButton, separator, beepButton, vibrateButton]
            .forEach { stackView.addArrangedSubview($0) }

        torchButton.isHidden = !config.isTorchButtonVisible
        switchButton.isHidden = !config.isCameraToggleButtonVisible
        beepButton.isHidden = !config.isBeepButtonVisible
        vibrateButton.isHidden = !config.isVibrateButtonVisible
        separator.isHidden = (torchButton.isHidden && switchButton.isHidden)
            || (beepButton.isHidden && vibrateButton.isHidden)

        beepButton.isSelected = config.isBeepEnabled
        vibrateButton.isSelected = config.isVibrateEnabled

        let topMenuVisible = [config.isCloseButtonVisible, config.isCameraToggleButtonVisible,
                              config.isTorchButtonVisible, config.isBeepButtonVisible,
                              config.isVibrateButtonVisible].contains(true)
        topMenu.isHidden = !topMenuVisible

        NSLayoutConstraint.activate([
            topMenu.topAnchor.constraint(equalTo: view.topAnchor),
            topMenu.bottomAnchor.constraint(equalTo: safeArea.topAnchor, constant: topMenuVisible ? 56 : 0),
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

        // A custom template owns the format, so the selector would only fight it.
        let showSelector = config.isFormatSelectorVisible && config.templateFile == nil
        bottomMenu.setSelectedOption(selectedOption.label)
        bottomMenu.backgroundColor = .black
        bottomMenu.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomMenu)
        bottomMenu.isHidden = !showSelector

        NSLayoutConstraint.activate([
            safeBottom.topAnchor.constraint(equalTo: safeArea.bottomAnchor),
            safeBottom.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            safeBottom.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            safeBottom.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            bottomMenu.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomMenu.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomMenu.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor),
            bottomMenu.heightAnchor.constraint(equalToConstant: showSelector ? 64 : 0),

            cameraView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            cameraView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            cameraView.topAnchor.constraint(equalTo: topMenu.bottomAnchor),
            cameraView.bottomAnchor.constraint(equalTo: bottomMenu.topAnchor)
        ])

        // Guide Frame
        guideBorder.addSubview(guideText)
        guideBorder.isHidden = !config.isGuideFrameVisible
        view.addSubview(guideBorder)

        NSLayoutConstraint.activate([
            guideText.centerXAnchor.constraint(equalTo: guideBorder.centerXAnchor),
            guideText.bottomAnchor.constraint(equalTo: guideBorder.bottomAnchor, constant: -8),
            guideText.widthAnchor.constraint(equalTo: guideBorder.widthAnchor, multiplier: 0.95),

            guideBorder.centerXAnchor.constraint(equalTo: cameraView.centerXAnchor),
            guideBorder.centerYAnchor.constraint(equalTo: cameraView.centerYAnchor),
        ])
        updateGuideConstraint()

        addCentredOnGuide(flipPromptImage, size: 120)
        addCentredOnGuide(scannerSpinner, size: 48)

        guideLabel.isHidden = !config.isGuideFrameVisible
        view.addSubview(guideLabel)
        view.addSubview(finishPromptLabel)

        NSLayoutConstraint.activate([
            guideLabel.centerXAnchor.constraint(equalTo: guideBorder.centerXAnchor),
            guideLabel.bottomAnchor.constraint(equalTo: guideBorder.topAnchor, constant: -16),

            finishPromptLabel.centerXAnchor.constraint(equalTo: cameraView.centerXAnchor),
            finishPromptLabel.topAnchor.constraint(equalTo: guideBorder.bottomAnchor, constant: 16)
        ])
        finishPromptLabel.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(onFinishPromptTapped)))

        closeButton.addTarget(self, action: #selector(onCloseButtonTouchUp), for: .touchUpInside)
        torchButton.addTarget(self, action: #selector(onTorchButtonTouchUp), for: .touchUpInside)
        switchButton.addTarget(self, action: #selector(onSwitchButtonTouchUp), for: .touchUpInside)
        beepButton.addTarget(self, action: #selector(onToggleButtonTouchUp), for: .touchUpInside)
        vibrateButton.addTarget(self, action: #selector(onToggleButtonTouchUp), for: .touchUpInside)

        bottomMenu.onChanged = { [weak self] selectedMode in
            self?.handleSelection(mode: selectedMode)
        }
    }

    /// Centres an overlay on the guide frame as a sibling, so hiding the frame keeps it visible (#63).
    private func addCentredOnGuide(_ subview: UIView, size: CGFloat) {
        view.addSubview(subview)
        NSLayoutConstraint.activate([
            subview.centerXAnchor.constraint(equalTo: guideBorder.centerXAnchor),
            subview.centerYAnchor.constraint(equalTo: guideBorder.centerYAnchor),
            subview.widthAnchor.constraint(equalToConstant: size),
            subview.heightAnchor.constraint(equalToConstant: size),
        ])
    }
}
