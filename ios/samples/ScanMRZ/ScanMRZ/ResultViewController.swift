//
//  ResultViewController.swift
//  ScanMRZ
//

import Foundation
import UIKit
import DynamsoftMRZScannerBundle
import DynamsoftCaptureVisionBundle

class ResultViewController: UIViewController {
    
    // MARK: - Data Properties
    var mrzData: MRZData?
    var portraitImage: UIImage?
    var primaryDocumentImage: UIImage?
    var primaryOriginalImage: UIImage?
    var secondaryDocumentImage: UIImage?
    var secondaryOriginalImage: UIImage?
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Person Info Header
    let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.boldSystemFont(ofSize: 24)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    let subInfoLabel: UILabel = {
        let label = UILabel()
        label.textColor = .lightGray
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    let portraitImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = UIColor.darkGray
        imageView.translatesAutoresizingMaskIntoConstraints = false
        // Set default placeholder from Media.xcassets
        imageView.image = UIImage(named: "user")
        return imageView
    }()
    
    // Custom Segmented Control
    let segmentContainerView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 16
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    let processedButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Processed", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        return button
    }()
    let originalButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Original", for: .normal)
        button.setTitleColor(.gray, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        return button
    }()
    let processedUnderline: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.heightAnchor.constraint(equalToConstant: 2).isActive = true
        return view
    }()
    let originalUnderline: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.heightAnchor.constraint(equalToConstant: 2).isActive = true
        return view
    }()
    private var isProcessedSelected = true

    /// Stands in for the tabs when only one set came back, styled like the sections below.
    let imagesHeaderLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // Collapsed, not merely hidden: a hidden view still occupies the space its constraints
    // reserve, so the heights and the gaps above them have to go to zero as well.
    private let processedSegmentStackView = UIStackView()
    private let originalSegmentStackView = UIStackView()

    private var segmentTopConstraint: NSLayoutConstraint!
    private var segmentHeightConstraint: NSLayoutConstraint!
    private var imageStackTopConstraint: NSLayoutConstraint!
    private var imageStackHeightConstraint: NSLayoutConstraint!

    // Document Images
    let imageStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 16
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    let primaryImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        return imageView
    }()
    
    let secondaryImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        return imageView
    }()
    
    // Personal Info Section
    let personalInfoLabel: UILabel = {
        let label = UILabel()
        label.text = "Personal Info"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    let personalInfoStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    // Document Info Section
    let documentInfoLabel: UILabel = {
        let label = UILabel()
        label.text = "Document Info"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    let documentInfoStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    // Raw MRZ Text Section
    let mrzLabel: UILabel = {
        let label = UILabel()
        label.text = "Raw MRZ Text"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    let mrzValueLabel: UILabel = {
        let label = UILabel()
        label.textColor = .lightGray
        label.font = UIFont.systemFont(ofSize: 12)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Bottom Buttons
    private let bottomButtonContainer = UIView()
    let rescanButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(" Re-scan", for: .normal)
        button.setImage(UIImage(named: "rescan"), for: .normal)
        button.tintColor = .white
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        return button
    }()
    let returnHomeButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(" Return home", for: .normal)
        button.setImage(UIImage(named: "return"), for: .normal)
        button.tintColor = .black
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.backgroundColor = .white
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        title = "Result"
        setupBottomButtons()
        setupContentUI()
        populateData()
        setupLongPressGestures()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = false
    }
    
    // MARK: - Setup UI
    private func setupContentUI() {
        // Setup ScrollView
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomButtonContainer.topAnchor, constant: -24),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        setupPersonInfoHeader()
        setupCustomSegmentedControl()
        setupDocumentImages()
        setupPersonalInfoSection()
        setupDocumentInfoSection()
        setupMRZSection()
    }
    
    private func setupPersonInfoHeader() {
        // Name Label
        contentView.addSubview(nameLabel)
        
        // Sub Info Label (gender, age, expiry)
        contentView.addSubview(subInfoLabel)
        
        // Portrait Image View
        contentView.addSubview(portraitImageView)
        
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            nameLabel.trailingAnchor.constraint(equalTo: portraitImageView.leadingAnchor, constant: -8),
            
            subInfoLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            subInfoLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            subInfoLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            
            portraitImageView.topAnchor.constraint(equalTo: nameLabel.topAnchor),
            portraitImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            portraitImageView.widthAnchor.constraint(equalToConstant: 88),
            portraitImageView.heightAnchor.constraint(equalToConstant: 100)
        ])
    }
    
    private func setupCustomSegmentedControl() {
        // Container view
        contentView.addSubview(segmentContainerView)
        processedSegmentStackView.addArrangedSubview(processedButton)
        processedSegmentStackView.addArrangedSubview(processedUnderline)
        processedSegmentStackView.axis = .vertical
        processedSegmentStackView.spacing = 2

        originalSegmentStackView.addArrangedSubview(originalButton)
        originalSegmentStackView.addArrangedSubview(originalUnderline)
        originalSegmentStackView.axis = .vertical
        originalSegmentStackView.spacing = 2

        segmentContainerView.addArrangedSubview(processedSegmentStackView)
        segmentContainerView.addArrangedSubview(originalSegmentStackView)
        
        segmentTopConstraint = segmentContainerView.topAnchor.constraint(equalTo: portraitImageView.bottomAnchor, constant: 24)
        segmentHeightConstraint = segmentContainerView.heightAnchor.constraint(equalToConstant: 30)

        // Shares the container's slot, so the images below stay anchored either way.
        contentView.addSubview(imagesHeaderLabel)

        NSLayoutConstraint.activate([
            segmentTopConstraint,
            segmentContainerView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            segmentHeightConstraint,

            imagesHeaderLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            imagesHeaderLabel.centerYAnchor.constraint(equalTo: segmentContainerView.centerYAnchor),
        ])

        processedButton.addTarget(self, action: #selector(processedTapped), for: .touchUpInside)
        originalButton.addTarget(self, action: #selector(originalTapped), for: .touchUpInside)
    }
    
    @objc private func processedTapped() {
        isProcessedSelected = true
        updateSegmentAppearance()
        updateDocumentImages()
    }
    
    @objc private func originalTapped() {
        isProcessedSelected = false
        updateSegmentAppearance()
        updateDocumentImages()
    }
    
    private func updateSegmentAppearance() {
        if isProcessedSelected {
            processedButton.setTitleColor(.white, for: .normal)
            originalButton.setTitleColor(.gray, for: .normal)
            processedUnderline.backgroundColor = .white
            originalUnderline.backgroundColor = .clear
        } else {
            processedButton.setTitleColor(.gray, for: .normal)
            originalButton.setTitleColor(.white, for: .normal)
            processedUnderline.backgroundColor = .clear
            originalUnderline.backgroundColor = .white
        }
    }
    
    private func setupDocumentImages() {
        contentView.addSubview(imageStackView)
        
        imageStackView.addArrangedSubview(primaryImageView)
        imageStackView.addArrangedSubview(secondaryImageView)
        
        imageStackTopConstraint = imageStackView.topAnchor.constraint(equalTo: segmentContainerView.bottomAnchor, constant: 16)
        imageStackHeightConstraint = imageStackView.heightAnchor.constraint(equalToConstant: 160)

        NSLayoutConstraint.activate([
            imageStackTopConstraint,
            imageStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            imageStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            imageStackHeightConstraint
        ])
    }
    
    private func setupPersonalInfoSection() {
        // Section Title
        contentView.addSubview(personalInfoLabel)
    
        // Stack View for info rows
        contentView.addSubview(personalInfoStackView)
        
        NSLayoutConstraint.activate([
            personalInfoLabel.topAnchor.constraint(equalTo: imageStackView.bottomAnchor, constant: 24),
            personalInfoLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            personalInfoStackView.topAnchor.constraint(equalTo: personalInfoLabel.bottomAnchor, constant: 12),
            personalInfoStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            personalInfoStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
    }
    
    private func setupDocumentInfoSection() {
        // Section Title
        contentView.addSubview(documentInfoLabel)
        
        // Stack View for info rows
        contentView.addSubview(documentInfoStackView)
        
        NSLayoutConstraint.activate([
            documentInfoLabel.topAnchor.constraint(equalTo: personalInfoStackView.bottomAnchor, constant: 24),
            documentInfoLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            documentInfoStackView.topAnchor.constraint(equalTo: documentInfoLabel.bottomAnchor, constant: 12),
            documentInfoStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            documentInfoStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
    }
    
    private func setupMRZSection() {
        // Section Title
        contentView.addSubview(mrzLabel)
        
        // MRZ Text
        contentView.addSubview(mrzValueLabel)
        
        NSLayoutConstraint.activate([
            mrzLabel.topAnchor.constraint(equalTo: documentInfoStackView.bottomAnchor, constant: 24),
            mrzLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            mrzValueLabel.topAnchor.constraint(equalTo: mrzLabel.bottomAnchor, constant: 12),
            mrzValueLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            mrzValueLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            mrzValueLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
    }
    
    /// Amber (#FFC107) used to color values whose MRZ check digit failed.
    private static let warningAmber = UIColor(red: 1.0, green: 193.0/255.0, blue: 7.0/255.0, alpha: 1.0)

    /// Styles `label` as a failed value: underlined text, so it reads as a tappable link,
    /// plus an inline amber icon. Renders with `label.font`, so set the font first.
    private static func applyFailedValue(_ text: String, to label: UILabel) {
        let font: UIFont = label.font
        let result = NSMutableAttributedString(string: text, attributes: [
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .foregroundColor: warningAmber,
            .font: font
        ])

        let iconHeight = font.pointSize * 1.2
        let attachment = NSTextAttachment()
        attachment.image = UIImage(
            systemName: "exclamationmark.circle.fill",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: iconHeight)
        )?.withTintColor(warningAmber, renderingMode: .alwaysOriginal)
        if let icon = attachment.image {
            // Width follows the symbol's own aspect ratio; y sits it on the text baseline.
            attachment.bounds = CGRect(x: 0, y: font.descender,
                                       width: iconHeight * icon.size.width / icon.size.height,
                                       height: iconHeight)
        }

        // The separating spaces stay outside the underline, as on Android.
        result.append(NSAttributedString(string: "  "))
        result.append(NSAttributedString(attachment: attachment))

        label.attributedText = result
        // The icon has no accessible text and color alone isn't a cue, so spell it out.
        label.accessibilityLabel = "\(text), validation failed"
    }

    private func createInfoRow(label: String, value: String, status: ValidationStatus = .none) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false

        let labelView = UILabel()
        labelView.text = label
        labelView.textColor = .lightGray
        labelView.font = UIFont.systemFont(ofSize: 14)
        labelView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(labelView)

        let failed = status == .failed
        let displayValue = value.isEmpty ? "N/A" : value

        let valueView = UILabel()
        valueView.font = UIFont.systemFont(ofSize: 14)
        valueView.textColor = .white
        // A failed value carries its own amber color in the attributed string.
        if failed {
            Self.applyFailedValue(displayValue, to: valueView)
        } else {
            valueView.text = displayValue
        }
        valueView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(valueView)

        NSLayoutConstraint.activate([
            labelView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            labelView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            labelView.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.5),

            valueView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            valueView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            valueView.leadingAnchor.constraint(equalTo: labelView.trailingAnchor, constant: 8),

            containerView.heightAnchor.constraint(equalToConstant: 20)
        ])

        if failed {
            let tap = UITapGestureRecognizer(target: self, action: #selector(showValidationInfoDialog))
            containerView.addGestureRecognizer(tap)
            containerView.isUserInteractionEnabled = true
        }

        return containerView
    }

    /// Validation styling for a label outside the info rows — the raw MRZ text. On `.failed`
    /// it gets the amber treatment and opens the dialog on tap; otherwise `defaultColor`.
    private func applyLabel(_ label: UILabel, text: String, status: ValidationStatus, defaultColor: UIColor) {
        let display = text.isEmpty ? "N/A" : text
        label.textColor = defaultColor
        guard status == .failed else {
            label.attributedText = nil
            label.accessibilityLabel = nil
            label.text = display
            return
        }

        Self.applyFailedValue(display, to: label)
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(showValidationInfoDialog)))
    }

    @objc private func showValidationInfoDialog() {
        let alert = UIAlertController(
            title: "Field validation warning",
            message: "This value doesn't match its check digit. The document may be invalid or altered.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Populate Data
    private func populateData() {
        guard let data = mrzData else { return }

        // Sex can now be empty when the field wasn't parsed — .capitalized returns "" safely.
        let genderText = data.sex.capitalized

        // No validation highlighting here: a compound line ("gender, age") tinted on one
        // field's status would imply both are invalid. The sections below do it per field.
        nameLabel.text = "\(data.firstName) \(data.lastName)".trimmingCharacters(in: .whitespaces)
        subInfoLabel.text = "\(genderText), \(data.age) years old\nExpiry: \(data.dateOfExpire)"

        // The portrait is returned by default, but is nil when none could be cropped —
        // a TD1/TD2 ID scanned MRZ-side only, for instance. Fall back to the placeholder.
        portraitImageView.image = portraitImage ?? UIImage(named: "user")

        // Document Images
        updateImageSectionVisibility()
        updateDocumentImages()

        // Personal Info
        personalInfoStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        personalInfoStackView.addArrangedSubview(createInfoRow(label: "Given Name",   value: data.firstName,     status: data.getFieldValidationStatus("firstName")))
        personalInfoStackView.addArrangedSubview(createInfoRow(label: "Surname",      value: data.lastName,      status: data.getFieldValidationStatus("lastName")))
        personalInfoStackView.addArrangedSubview(createInfoRow(label: "Date of Birth",value: data.dateOfBirth,   status: data.getFieldValidationStatus("dateOfBirth")))
        personalInfoStackView.addArrangedSubview(createInfoRow(label: "Gender",       value: genderText,         status: data.getFieldValidationStatus("sex")))
        personalInfoStackView.addArrangedSubview(createInfoRow(label: "Nationality",  value: data.nationalityRaw,status: data.getFieldValidationStatus("nationality")))

        // Document Info
        documentInfoStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        // Doc Type is derived from codeType — not independently validated.
        documentInfoStackView.addArrangedSubview(createInfoRow(label: "Doc. Type",   value: data.documentType == "MRTD_TD3_PASSPORT" ? "Passport" : "ID"))
        documentInfoStackView.addArrangedSubview(createInfoRow(label: "Doc. Number", value: data.documentNumber, status: data.getFieldValidationStatus("documentNumber")))
        documentInfoStackView.addArrangedSubview(createInfoRow(label: "Expiry Date", value: data.dateOfExpire,   status: data.getFieldValidationStatus("dateOfExpire")))

        // Tappable too: a line-composite failure can flag the raw MRZ when no individual
        // field failed — corruption in a field without its own check digit, say.
        applyLabel(mrzValueLabel,
                   text: data.mrzText,
                   status: data.getFieldValidationStatus("mrzText"),
                   defaultColor: .lightGray)
    }
    
    /// Shows each segment only when its own image set came back, and collapses the section
    /// when none did — `returnOriginalImage` is false by default, so "Processed" often stands alone.
    private func updateImageSectionVisibility() {
        let hasProcessed = primaryDocumentImage != nil || secondaryDocumentImage != nil
        let hasOriginal = primaryOriginalImage != nil || secondaryOriginalImage != nil
        let hasAnyImage = hasProcessed || hasOriginal

        // Tabs only when there are two sets to switch between; one set gets a plain header.
        let showsTabs = hasProcessed && hasOriginal
        if !showsTabs {
            isProcessedSelected = hasProcessed
        }
        updateSegmentAppearance()

        segmentContainerView.isHidden = !showsTabs
        imagesHeaderLabel.isHidden = showsTabs || !hasAnyImage
        imagesHeaderLabel.text = hasProcessed ? "Processed Image(s)" : "Original Image(s)"

        segmentTopConstraint.constant = hasAnyImage ? 24 : 0
        segmentHeightConstraint.constant = hasAnyImage ? 30 : 0

        imageStackView.isHidden = !hasAnyImage
        imageStackHeightConstraint.constant = hasAnyImage ? 160 : 0
        imageStackTopConstraint.constant = hasAnyImage ? 16 : 0
    }

    private func updateDocumentImages() {
        if isProcessedSelected {
            primaryImageView.image = primaryDocumentImage
            secondaryImageView.image = secondaryDocumentImage
            primaryImageView.isHidden = primaryDocumentImage == nil
            secondaryImageView.isHidden = secondaryDocumentImage == nil
        } else {
            primaryImageView.image = primaryOriginalImage
            secondaryImageView.image = secondaryOriginalImage
            primaryImageView.isHidden = primaryOriginalImage == nil
            secondaryImageView.isHidden = secondaryOriginalImage == nil
        }
    }

    // MARK: - Bottom Buttons
    private func setupBottomButtons() {
        bottomButtonContainer.translatesAutoresizingMaskIntoConstraints = false
        bottomButtonContainer.backgroundColor = .black
        view.addSubview(bottomButtonContainer)

        rescanButton.addTarget(self, action: #selector(rescanTapped), for: .touchUpInside)
        bottomButtonContainer.addSubview(rescanButton)

        returnHomeButton.addTarget(self, action: #selector(returnHomeTapped), for: .touchUpInside)
        bottomButtonContainer.addSubview(returnHomeButton)
        
        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            bottomButtonContainer.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            bottomButtonContainer.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            bottomButtonContainer.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -16),
            
            rescanButton.topAnchor.constraint(equalTo: bottomButtonContainer.topAnchor),
            rescanButton.leadingAnchor.constraint(equalTo: bottomButtonContainer.leadingAnchor, constant: 20),
            rescanButton.bottomAnchor.constraint(equalTo: bottomButtonContainer.bottomAnchor),
            rescanButton.heightAnchor.constraint(equalToConstant: 48),
            
            returnHomeButton.topAnchor.constraint(equalTo: bottomButtonContainer.topAnchor),
            returnHomeButton.leadingAnchor.constraint(equalTo: rescanButton.trailingAnchor, constant: 16),
            returnHomeButton.trailingAnchor.constraint(equalTo: bottomButtonContainer.trailingAnchor, constant: -20),
            returnHomeButton.bottomAnchor.constraint(equalTo: bottomButtonContainer.bottomAnchor),
            returnHomeButton.heightAnchor.constraint(equalToConstant: 48),
            returnHomeButton.widthAnchor.constraint(equalTo: rescanButton.widthAnchor)
        ])
    }
    
    @objc private func rescanTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func returnHomeTapped() {
        navigationController?.popToRootViewController(animated: true)
    }
}

// MARK: - Long Press to Save Image
extension ResultViewController {
    private func setupLongPressGestures() {
        let imageViews = [portraitImageView, primaryImageView, secondaryImageView]
        
        for imageView in imageViews {
            imageView.isUserInteractionEnabled = true
            let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
            imageView.addGestureRecognizer(longPress)
        }
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began,
              let imageView = gesture.view as? UIImageView,
              let image = imageView.image else { return }

        let alert = UIAlertController(title: "Save Image", message: "Would you like to save this image to your photos?", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // Support for iPad popovers
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = imageView
            popoverController.sourceRect = imageView.bounds
        }
        
        present(alert, animated: true)
    }

    // MARK: - Save Image Callback
    @objc private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        // This callback carries no thread guarantee, so hop before touching UIKit.
        DispatchQueue.main.async { [weak self] in
            let saved = error == nil
            let alert = UIAlertController(
                title: saved ? "Saved!" : "Save Error",
                message: error?.localizedDescription ?? "The image has been saved to your library.",
                preferredStyle: .alert)
            // Success fades itself out below, but the OK action stays so a missed
            // dismissal never leaves the user with an alert they cannot close.
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self?.present(alert, animated: true)

            guard saved else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak alert] in
                alert?.dismiss(animated: true)
            }
        }
    }
}
