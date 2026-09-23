//
//  ViewController.swift
//  ScanMRZ
//

import UIKit
import DynamsoftMRZScannerBundle

/// The images a finished scan carries, decoded together off the main thread.
private typealias ScannedImages = (portrait: UIImage?, primaryDoc: UIImage?,
                                   primaryOrig: UIImage?, secondaryDoc: UIImage?,
                                   secondaryOrig: UIImage?)

/// Home screen: launches the scanner and routes the result onward or reports it here.
class ViewController: UIViewController {

    private let button = ViewController.makeStyledButton(title: "Scan an MRZ")
    /// Carries the canceled message and any error string.
    private let label = UILabel()
    /// Shown only for a camera-permission denial — the one failure the user can fix.
    private let settingsButton = ViewController.makeStyledButton(title: "Open Settings", fontSize: 16)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setup()
        setupAppearance()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // The result screen shows the bar, so hide it on every return, not just first load.
        navigationController?.navigationBar.isHidden = true
    }

    @objc func buttonTapped() {
        let config = MRZScannerConfig()
        // A trial license, so it needs a network connection. Request your own at
        // https://www.dynamsoft.com/customer/license/trialLicense?product=mrz&utm_source=samples&package=ios
        config.license = "DLS2eyJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSJ9"

        // Every setting below is commented out at the opposite of its default — uncomment to try.

        // Restrict recognition to one document family. Default is .all, which reads both.
        //config.documentType = .passport
        // Your own Capture Vision template (path or inline JSON); outranks documentType.
        //config.templateFile = "MyTemplate.json"

        // Scanner controls. Every one of these is visible by default.
        //config.isCloseButtonVisible = false         // Leaves no way out of the scanner.
        //config.isTorchButtonVisible = false         // Hides the torch toggle.
        //config.isCameraToggleButtonVisible = false  // Hides the front/back camera toggle.
        //config.isBeepButtonVisible = false          // Hides the beep toggle.
        //config.isVibrateButtonVisible = false       // Hides the vibrate toggle.
        //config.isFormatSelectorVisible = false      // Hides the Both / ID / Passport selector.
        //config.isGuideFrameVisible = false          // Hides the guide frame and its prompt.

        // Both off by default; the buttons above toggle them, so this is just the opening state.
        //config.isBeepEnabled = true
        //config.isVibrateEnabled = true

        // Crops come back by default, the full camera frame does not.
        //config.returnDocumentImage = false
        //config.returnPortraitImage = false
        //config.returnOriginalImage = true

        // Suppress the scanner's own permission alert; either way it arrives as an .exception.
        //config.isCameraPermissionPromptEnabled = false

        let vc = MRZScannerViewController()
        vc.config = config
        vc.onScannedResult = { [weak self] result in
            // Decode off the main thread — converting full frames on main would stall the UI.
            let images: ScannedImages = (
                portrait:      try? result.getPortraitImage()?.toUIImage(),
                primaryDoc:    try? result.getDocumentImage(.mrz)?.toUIImage(),
                primaryOrig:   try? result.getOriginalImage(.mrz)?.toUIImage(),
                secondaryDoc:  try? result.getDocumentImage(.opposite)?.toUIImage(),
                secondaryOrig: try? result.getOriginalImage(.opposite)?.toUIImage()
            )
            DispatchQueue.main.async { self?.handle(result, images) }
        }

        label.isHidden = true
        settingsButton.isHidden = true
        navigationController?.pushViewController(vc, animated: true)
    }

    /// Routes the three result statuses; the result screen pushes on top so "Re-scan" can pop.
    private func handle(_ result: MRZScanResult, _ images: ScannedImages) {
        switch result.resultStatus {
        case .finished:
            guard let data = result.data else {
                // Nothing to show, so don't strand the user on the scanner.
                report("Scan returned no data")
                return
            }
            let resultVC = ResultViewController()
            resultVC.mrzData = data
            resultVC.portraitImage = images.portrait
            resultVC.primaryDocumentImage = images.primaryDoc
            resultVC.primaryOriginalImage = images.primaryOrig
            resultVC.secondaryDocumentImage = images.secondaryDoc
            resultVC.secondaryOriginalImage = images.secondaryOrig
            navigationController?.pushViewController(resultVC, animated: true)
        case .canceled:
            // The user closed the scanner. There is no data and nothing went wrong.
            report("Scan canceled")
        case .exception:
            report(result.errorString ?? "")
            // Only a user denial is fixable in Settings; policy-restricted has no toggle there.
            settingsButton.isHidden =
                result.errorCode != ErrorCode.cameraPermissionDenied.rawValue
        @unknown default:
            break
        }
    }

    /// Leaves `message` on this screen and returns to it from the scanner.
    private func report(_ message: String) {
        label.text = message
        label.isHidden = false
        navigationController?.popViewController(animated: true)
    }

    /// The scanner's own alert is gone by the time the message shows, so keep a route here.
    @objc func openSettingsTapped() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - Setup UI

    /// Both buttons are the same black pill; only the caption and type size differ.
    private static func makeStyledButton(title: String, fontSize: CGFloat? = nil) -> UIButton {
        let button = UIButton()
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .black
        button.layer.cornerRadius = 8
        button.clipsToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        if let fontSize = fontSize {
            button.titleLabel?.font = UIFont.systemFont(ofSize: fontSize)
        }
        return button
    }

    private func setup() {
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        view.addSubview(button)

        label.numberOfLines = 0
        label.textColor = .black
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 20)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        settingsButton.isHidden = true
        settingsButton.addTarget(self, action: #selector(openSettingsTapped), for: .touchUpInside)
        view.addSubview(settingsButton)

        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -10),
            button.heightAnchor.constraint(equalToConstant: 50),
            button.widthAnchor.constraint(equalToConstant: 150),

            label.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: safeArea.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 30),
            label.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -30),

            settingsButton.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
            settingsButton.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 20),
            settingsButton.heightAnchor.constraint(equalToConstant: 44),
            settingsButton.widthAnchor.constraint(equalToConstant: 180)
        ])
    }

    /// The bar is hidden here but shown on the result screen, so style it once from the root.
    private func setupAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .black
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = UIColor.white
    }
}
