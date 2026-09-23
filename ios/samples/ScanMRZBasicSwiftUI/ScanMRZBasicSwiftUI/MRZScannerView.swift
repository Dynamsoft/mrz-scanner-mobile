//
//  MRZScannerView.swift
//  ScanMRZBasicSwiftUI
//
//  Bridges the UIKit `MRZScannerViewController` into SwiftUI.
//

import SwiftUI
import DynamsoftMRZScannerBundle

/// `UIViewControllerRepresentable` wrapper around the SDK's ready-to-use scanner.
///
/// The SDK ships its scanner as a `UIViewController` that reports through the
/// `onScannedResult` closure, so SwiftUI reaches it through this bridge. The closure
/// fires on a background queue, which is why the caller hops to the main queue before
/// touching any SwiftUI state.
struct MRZScannerView: UIViewControllerRepresentable {

    /// Called once the scanner finishes, is canceled, or fails.
    let onScannedResult: (MRZScanResult) -> Void

    func makeUIViewController(context: Context) -> MRZScannerViewController {
        let config = MRZScannerConfig()
        // A trial license, so it needs a network connection. Request your own at
        // https://www.dynamsoft.com/customer/license/trialLicense?product=mrz&utm_source=samples&package=ios
        config.license = "DLS2eyJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSJ9"

        let scanner = MRZScannerViewController()
        scanner.config = config
        scanner.onScannedResult = onScannedResult
        return scanner
    }

    func updateUIViewController(_ uiViewController: MRZScannerViewController,
                                context: Context) {
        // The scanner is configured once in makeUIViewController and owns its own state
        // from then on, so there is nothing to push down on SwiftUI state changes.
    }
}
