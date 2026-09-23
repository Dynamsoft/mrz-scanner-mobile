//
//  ViewController.swift
//  ScanMRZBasic
//

import UIKit
import DynamsoftMRZScannerBundle
import DynamsoftCaptureVisionBundle

/// Presents the built-in MRZ scanner and renders the result on this same screen.
///
/// The whole sample is this one view controller. See the ScanMRZ sample for a fuller
/// app: document images, per-field explanations and permission recovery.
class ViewController: UIViewController {

    /// Amber (#FFC107) marks a value that does not match its check digit.
    private static let warningAmber =
        UIColor(red: 1, green: 193 / 255, blue: 7 / 255, alpha: 1)

    private let scanButton = UIButton(type: .system)
    /// Carries the canceled message and any error string.
    private let statusLabel = UILabel()
    private let portraitView = UIImageView()
    private let portraitRow = UIStackView()
    /// Holds the portrait and the field rows, rebuilt on every successful scan.
    private let resultStack = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
    }

    @objc private func scanTapped() {
        let config = MRZScannerConfig()
        // A trial license, so it needs a network connection. Request your own at
        // https://www.dynamsoft.com/customer/license/trialLicense?product=mrz&utm_source=samples&package=ios
        config.license = "DLS2eyJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSJ9"

        let scanner = MRZScannerViewController()
        scanner.config = config
        // The result arrives off the main thread, so hop back before touching UIKit.
        // The scanner does not close itself — dismissing it is the caller's job.
        scanner.onScannedResult = { [weak self] result in
            DispatchQueue.main.async {
                self?.dismiss(animated: true)
                self?.show(result)
            }
        }
        scanner.modalPresentationStyle = .fullScreen
        present(scanner, animated: true)
    }

    /// Renders one of the three result statuses the scanner can come back with.
    private func show(_ result: MRZScanResult) {
        switch result.resultStatus {
        case .finished:
            guard let data = result.data else { return }
            show(data, portrait: try? result.getPortraitImage()?.toUIImage())
        case .canceled:
            // The user closed the scanner. There is no data and nothing went wrong.
            showStatus("Scan canceled")
        case .exception:
            // The scanner asks for camera access itself, so a denial lands here as a
            // readable error string — this sample needs no permission code of its own.
            showStatus(result.errorString ?? "")
        @unknown default:
            break
        }
    }

    private func showStatus(_ message: String) {
        statusLabel.text = message
        statusLabel.isHidden = false
        resultStack.isHidden = true
    }

    private func show(_ data: MRZData, portrait: UIImage?) {
        statusLabel.isHidden = true
        resultStack.isHidden = false
        resultStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // The portrait is returned by default, but is nil when none could be cropped.
        if let portrait = portrait {
            portraitView.image = portrait
            resultStack.addArrangedSubview(portraitRow)
            resultStack.setCustomSpacing(16, after: portraitRow)
        }

        // Validation is per field, so a full name that joins two of them is flagged
        // when either half fails.
        let firstNameStatus = data.getFieldValidationStatus("firstName")
        let nameStatus = firstNameStatus == .failed
            ? firstNameStatus
            : data.getFieldValidationStatus("lastName")
        let fullName = "\(data.firstName) \(data.lastName)"
            .trimmingCharacters(in: .whitespaces)

        addRow("Full Name", fullName, nameStatus)
        addRow("Document Number", data.documentNumber,
               data.getFieldValidationStatus("documentNumber"))
        addRow("Nationality", data.nationality,
               data.getFieldValidationStatus("nationality"))
        addRow("Date of Birth", data.dateOfBirth,
               data.getFieldValidationStatus("dateOfBirth"))
        addRow("Date of Expiry", data.dateOfExpire,
               data.getFieldValidationStatus("dateOfExpire"))
        // The document type comes from the MRZ layout itself, so it has no check digit.
        addRow("Document Type", data.documentType)
        addRow("Raw MRZ Text", data.mrzText,
               data.getFieldValidationStatus("mrzText"), monospaced: true)
    }

    /// Appends a caption and its value, or "N/A" when the parser extracted nothing.
    /// A value that failed its check digit is colored amber.
    private func addRow(_ caption: String,
                        _ value: String,
                        _ status: ValidationStatus = .none,
                        monospaced: Bool = false) {
        let captionLabel = UILabel()
        captionLabel.text = caption
        captionLabel.font = .systemFont(ofSize: 12)
        captionLabel.textColor = .secondaryLabel

        let valueLabel = UILabel()
        valueLabel.text = value.isEmpty ? "N/A" : value
        valueLabel.numberOfLines = 0
        valueLabel.textColor = status == .failed ? Self.warningAmber : .label
        valueLabel.font = monospaced
            ? .monospacedSystemFont(ofSize: 14, weight: .semibold)
            : .boldSystemFont(ofSize: 16)

        resultStack.addArrangedSubview(captionLabel)
        resultStack.addArrangedSubview(valueLabel)
        resultStack.setCustomSpacing(12, after: valueLabel)
    }

    /// Deliberately plain: a scroll view of results with the scan button pinned below
    /// it. Styling belongs in the ScanMRZ sample, not here.
    private func setupUI() {
        scanButton.setTitle("Scan an MRZ", for: .normal)
        scanButton.titleLabel?.font = .systemFont(ofSize: 18)
        scanButton.setTitleColor(.white, for: .normal)
        scanButton.backgroundColor = .systemBlue
        scanButton.layer.cornerRadius = 8
        scanButton.addTarget(self, action: #selector(scanTapped), for: .touchUpInside)

        statusLabel.font = .systemFont(ofSize: 16)
        statusLabel.numberOfLines = 0
        statusLabel.isHidden = true

        portraitView.contentMode = .scaleAspectFit
        // A trailing spacer keeps the portrait its own size at the leading edge.
        portraitRow.addArrangedSubview(portraitView)
        portraitRow.addArrangedSubview(UIView())

        resultStack.axis = .vertical
        resultStack.spacing = 2
        resultStack.isHidden = true

        let content = UIStackView(arrangedSubviews: [statusLabel, resultStack])
        content.axis = .vertical
        content.spacing = 16
        content.translatesAutoresizingMaskIntoConstraints = false

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scanButton.translatesAutoresizingMaskIntoConstraints = false
        portraitView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(content)
        view.addSubview(scrollView)
        view.addSubview(scanButton)

        let safeArea = view.safeAreaLayoutGuide
        let contentGuide = scrollView.contentLayoutGuide
        let frameGuide = scrollView.frameLayoutGuide
        NSLayoutConstraint.activate([
            portraitView.widthAnchor.constraint(equalToConstant: 96),
            portraitView.heightAnchor.constraint(equalToConstant: 128),

            scrollView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: scanButton.topAnchor,
                                               constant: -16),

            content.topAnchor.constraint(equalTo: contentGuide.topAnchor, constant: 16),
            content.bottomAnchor.constraint(equalTo: contentGuide.bottomAnchor,
                                            constant: -16),
            content.leadingAnchor.constraint(equalTo: frameGuide.leadingAnchor,
                                             constant: 16),
            content.trailingAnchor.constraint(equalTo: frameGuide.trailingAnchor,
                                              constant: -16),

            scanButton.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor,
                                                constant: 16),
            scanButton.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor,
                                                 constant: -16),
            scanButton.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor,
                                               constant: -16),
            scanButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
}
