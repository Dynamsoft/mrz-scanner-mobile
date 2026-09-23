//
//  MRZScannerView.swift
//  ScanMRZSwiftUI
//
//  Bridges the UIKit `MRZScannerViewController` into SwiftUI.
//

import SwiftUI
import DynamsoftMRZScannerBundle

/// `UIViewControllerRepresentable` wrapper around the SDK's ready-to-use scanner.
///
/// `onScannedResult` fires on a background queue, which is why the caller hops to the
/// main queue before touching any SwiftUI state.
struct MRZScannerView: UIViewControllerRepresentable {

    /// Called once the scanner finishes, is canceled, or fails.
    let onScannedResult: (MRZScanResult) -> Void

    func makeUIViewController(context: Context) -> MRZScannerViewController {
        let vc = MRZScannerViewController()

        let config = MRZScannerConfig()
        // Initialize the license.
        // The license string here is a trial license. Note that network connection is required for this license to work.
        // You can request an extension via the following link: https://www.dynamsoft.com/customer/license/trialLicense?product=mrz&utm_source=samples&package=ios
        config.license = "DLS2eyJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSJ9"

        // Everything below is left at its default — the scanner as it ships. Each is listed
        // commented out at the opposite of its default, so uncommenting one shows what it does.

        // Restrict recognition to one document family. Default is .all, which reads both.
        //config.documentType = .passport
        // Drive capture with your own Capture Vision template (file path or inline JSON).
        // Default is nil; a template set here outranks documentType.
        //config.templateFile = "MyTemplate.json"

        // Scanner controls. Every one of these is visible by default.
        //config.isCloseButtonVisible = false         // Leaves no way out of the scanner.
        //config.isTorchButtonVisible = false         // Hides the torch toggle.
        //config.isCameraToggleButtonVisible = false  // Hides the front/back camera toggle.
        //config.isBeepButtonVisible = false          // Hides the beep toggle.
        //config.isVibrateButtonVisible = false       // Hides the vibrate toggle.
        //config.isFormatSelectorVisible = false      // Hides the Both / ID / Passport selector.
        //config.isGuideFrameVisible = false          // Hides the guide frame and its prompt.

        // Scan feedback, both off by default. The buttons above toggle them at runtime,
        // so these only decide the state the scanner opens in.
        //config.isBeepEnabled = true
        //config.isVibrateEnabled = true

        // Returned images. Crops come back by default, the full camera frame does not.
        // ResultView shows crops under "Processed", full frames under "Original".
        //config.returnDocumentImage = false
        //config.returnPortraitImage = false
        //config.returnOriginalImage = true

        // Suppress the scanner's own "Open Settings" alert and handle the denial from
        // onScannedResult alone. Default is true; either way it arrives as an .exception.
        //config.isCameraPermissionPromptEnabled = false

        vc.config = config

        vc.onScannedResult = onScannedResult
        return vc
    }

    func updateUIViewController(_ uiViewController: MRZScannerViewController, context: Context) {
        // The scanner is configured once in makeUIViewController and owns its own state
        // from then on, so there is nothing to push down on SwiftUI state changes.
    }
}
