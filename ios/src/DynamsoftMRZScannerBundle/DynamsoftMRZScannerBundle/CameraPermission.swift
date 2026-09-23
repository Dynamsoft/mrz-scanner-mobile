//
//  CameraPermission.swift
//  DynamsoftMRZScannerBundle
//
//  Copyright © Dynamsoft Corporation.  All rights reserved.
//

import AVFoundation
import UIKit

// MARK: - Camera Permission
extension MRZScannerViewController {

    /// Gates the camera on authorization. Without this the scanner opens the camera
    /// unconditionally, and a denied user sits on a blank preview with nothing reporting why.
    func startCaptureIfAuthorized() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            startCapture()
        case .notDetermined:
            // Asking explicitly keeps the timing under the scanner's control.
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    guard let self = self, self.isAppeared else { return }
                    if granted { self.startCapture() } else { self.handleCameraPermissionDenied(.denied) }
                }
            }
        case .restricted:
            handleCameraPermissionDenied(.restricted)
        default:
            handleCameraPermissionDenied(.denied)
        }
    }

    /// Offers a route into Settings before reporting, so an integrator with no permission
    /// handling still gets a usable flow. `isCameraPermissionPromptEnabled = false` skips it.
    func handleCameraPermissionDenied(_ status: AVAuthorizationStatus) {
        guard config.isCameraPermissionPromptEnabled else {
            reportCameraPermissionDenied(status)
            return
        }
        // An alert presented before the view joins the window is silently dropped, so defer to
        // viewDidAppear; the .notDetermined path resolves later and can present immediately.
        if view.window == nil {
            pendingPermissionDenial = status
        } else {
            presentCameraPermissionAlert(status)
        }
    }

    func presentCameraPermissionAlert(_ status: AVAuthorizationStatus) {
        let alert = UIAlertController(title: "Camera Access Needed",
                                      message: cameraPermissionMessage(for: status),
                                      preferredStyle: .alert)
        // Under .restricted the block is device policy, so the deep link would be a dead end.
        if status != .restricted, let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { [weak self] _ in
                UIApplication.shared.open(settingsURL)
                self?.reportCameraPermissionDenied(status)
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.reportCameraPermissionDenied(status)
        })
        present(alert, animated: true)
    }

    /// The code distinguishes the two remediations, so an integrator can decide whether to
    /// offer Settings without re-deriving the status through AVFoundation.
    private func reportCameraPermissionDenied(_ status: AVAuthorizationStatus) {
        let code: ErrorCode = status == .restricted ? .cameraPermissionRestricted : .cameraPermissionDenied
        onScannedResult?(.init(resultStatus: .exception,
                               errorCode: code.rawValue,
                               errorString: cameraPermissionMessage(for: status)))
    }

    /// `.restricted` differs because device policy, not the user, withholds access — so
    /// pointing them at Settings will not help.
    private func cameraPermissionMessage(for status: AVAuthorizationStatus) -> String {
        status == .restricted
            ? "Camera access is restricted on this device and cannot be granted by the user."
            : "Camera access is denied. Enable camera access for this app in Settings to scan."
    }
}
