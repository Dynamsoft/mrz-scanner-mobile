//
//  MRZScannerViewController+Guide.swift
//  DynamsoftMRZScannerBundle
//
//  Copyright © Dynamsoft Corporation.  All rights reserved.
//

import UIKit
import DynamsoftCaptureVisionBundle

extension MRZScannerViewController {

    enum GuideFrameMode {
        case original
        case scannedOneSide
        case scannedBothSides
        case scannedMRZWithoutPortrait
        case scannedMRZWithPortrait
        case scannedMRZ

        /// `nil` is idle; `returnWhite` false holds the border green through the handover (#68).
        var message: (highlighted: String?, normal: String?, returnWhite: Bool)? {
            switch self {
            case .original:                  return nil
            case .scannedOneSide:            return ("MRZ scanned ✓", "Flip and scan the other side", true)
            case .scannedBothSides:          return ("MRZ scanned ✓\nBoth sides scanned ✓", nil, false)
            // Stays up for the portrait timeout, so the frame goes back to white.
            case .scannedMRZWithoutPortrait: return ("MRZ scanned ✓", "Finding portrait...", true)
            case .scannedMRZWithPortrait:    return ("MRZ scanned ✓\nPortrait scanned ✓", nil, false)
            case .scannedMRZ:                return ("MRZ scanned ✓", nil, false)
            }
        }
    }

    private static let spinnerKey = "spinnerRotation"
}

// MARK: - Guide Frame Geometry
extension MRZScannerViewController {

    /// Frame size as a fraction of the camera view; layout and scan region share it, so both agree.
    private var guideFrameMultipliers: (width: CGFloat, height: CGFloat) {
        traitCollection.verticalSizeClass == .regular ? (0.9, 0.35) : (0.6, 0.8)
    }

    func updateGuideConstraint() {
        guideWidthConstraint?.isActive = false
        guideHeightConstraint?.isActive = false

        let multipliers = guideFrameMultipliers
        guideWidthConstraint = guideBorder.widthAnchor.constraint(
            equalTo: cameraView.widthAnchor, multiplier: multipliers.width)
        guideHeightConstraint = guideBorder.heightAnchor.constraint(
            equalTo: cameraView.heightAnchor, multiplier: multipliers.height)

        guideWidthConstraint?.isActive = true
        guideHeightConstraint?.isActive = true
    }

    /// Hiding the frame hides only its drawing, so scan the whole preview, not an invisible box (#63).
    func applyScanRegionToDCE() {
        let region: Rect
        if config.isGuideFrameVisible {
            let multipliers = guideFrameMultipliers
            region = Rect(left: (1 - multipliers.width) / 2, top: (1 - multipliers.height) / 2,
                          right: (1 + multipliers.width) / 2, bottom: (1 + multipliers.height) / 2,
                          measuredInPercentage: true)
        } else {
            region = Rect(left: 0, top: 0, right: 1, bottom: 1, measuredInPercentage: true)
        }
        try? dce.setScanRegion(region)
    }
}

// MARK: - Guide Frame State
extension MRZScannerViewController {

    func setGuideFrame(with mode: GuideFrameMode, completion: (() -> Void)? = nil) {
        // Only .scannedOneSide waits on another side, so it alone flips.
        let awaitingOtherSide = (mode == .scannedOneSide)
        if !awaitingOtherSide { stopFlipAnimation() }
        // Both waiting states already hold an MRZ, so the format is locked in. Matches Android.
        bottomMenu.isEnabled = !(awaitingOtherSide || mode == .scannedMRZWithoutPortrait)

        guard let text = mode.message else {
            guideBorder.layer.borderColor = UIColor.white.cgColor
            guideText.isHidden = false
            setGuideLabel(highlightedText: nil, normalText: "Scan the MRZ side first")
            completion?()
            return
        }

        performScanAnimation(
            highlightedText: text.highlighted,
            normalText: text.normal,
            returnWhite: text.returnWhite,
            completion: awaitingOtherSide ? { [weak self] in
                self?.startFlipAnimation()
                completion?()
            } : completion
        )
    }

    func setGuideLabel(highlightedText: String?, normalText: String?) {
        let parts = [highlightedText, normalText].compactMap { $0 }.filter { !$0.isEmpty }
        guard !parts.isEmpty else {
            guideLabel.attributedText = nil
            return
        }
        guideLabel.attributedText = promptText(parts.joined(separator: "\n"),
                                               highlighted: highlightedText, lineSpacing: 4)
    }

    /// - Parameter returnWhite: fades the border back to white first; callback timing is unchanged.
    private func performScanAnimation(highlightedText: String?, normalText: String?,
                                      returnWhite: Bool = true, completion: (() -> Void)?) {
        guideBorder.layer.borderColor = UIColor.systemGreen.cgColor

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            guard let self = self else { return }
            UIView.transition(
                with: self.guideLabel,
                duration: 0.3,
                options: [.transitionCrossDissolve],
                animations: {
                    self.setGuideLabel(highlightedText: highlightedText, normalText: normalText)
                    self.guideText.isHidden = true
                },
                completion: { _ in
                    guard returnWhite else {
                        // Hold the green, but wait out the fade's interval so handover timing holds.
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { completion?() }
                        return
                    }
                    UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut],
                                   animations: { self.guideBorder.layer.borderColor = UIColor.white.cgColor },
                                   completion: { _ in completion?() })
                }
            )
        }
    }
}

// MARK: - Flip Prompt & Spinner
extension MRZScannerViewController {

    func startFlipAnimation() {
        flipPromptImage.image = flipOriginalImage
        flipPromptImage.isHidden = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let self = self, !self.flipPromptImage.isHidden else { return }
            UIView.transition(
                with: self.flipPromptImage,
                duration: 1.5,
                options: [.transitionFlipFromRight],
                animations: { self.flipPromptImage.image = self.flipAfterImage },
                completion: { finished in
                    guard finished else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                        self?.stopFlipAnimation()
                    }
                }
            )
        }
    }

    func stopFlipAnimation() {
        flipPromptImage.layer.removeAllAnimations()
        flipPromptImage.isHidden = true
        flipPromptImage.image = flipOriginalImage
    }

    /// Driven per frame, so an already-running spinner must cost nothing.
    func startScannerSpinner() {
        guard scannerSpinner.isHidden else { return }
        scannerSpinner.isHidden = false
        scannerSpinner.transform = .identity
        // Respect motion-reduction: show the static icon, no rotation.
        guard !UIAccessibility.isReduceMotionEnabled else { return }

        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.fromValue = 0
        rotation.toValue = 2 * Double.pi
        rotation.duration = 1.0
        rotation.repeatCount = .infinity
        rotation.isRemovedOnCompletion = false
        scannerSpinner.layer.add(rotation, forKey: Self.spinnerKey)
    }

    func stopScannerSpinner() {
        guard !scannerSpinner.isHidden else { return }
        scannerSpinner.layer.removeAnimation(forKey: Self.spinnerKey)
        scannerSpinner.transform = .identity
        scannerSpinner.isHidden = true
    }
}

// MARK: - Portrait Timeout
extension MRZScannerViewController {

    func startPortraitTimeout() {
        cancelPortraitTimeout()
        portraitTimeoutTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            self?.onPortraitTimeout()
        }
    }

    func cancelPortraitTimeout() {
        portraitTimeoutTimer?.invalidate()
        portraitTimeoutTimer = nil
    }

    private func onPortraitTimeout() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.finishPromptLabel.isHidden = false
            self.stopFlipAnimation()
            self.setGuideLabel(highlightedText: "MRZ scanned ✓", normalText: "No portrait detected")
        }
    }
}
