//
//  ResultViewController.swift
//  ScanMRZ
//
//  Created by dynamsoft on 2026/2/11.
//

import Foundation
import UIKit
import DynamsoftMRZScannerBundle

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
    
    // Document Images
    let imageStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 16
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.tag = 300
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
    
    // Dropdown Menu
    private let dropdownView = UIView()
    
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
        let leftStackView = UIStackView(arrangedSubviews: [processedButton, processedUnderline])
        leftStackView.axis = .vertical
        leftStackView.spacing = 2
        
        let rightStackView = UIStackView(arrangedSubviews: [originalButton, originalUnderline])
        rightStackView.axis = .vertical
        rightStackView.spacing = 2
        
        segmentContainerView.addArrangedSubview(leftStackView)
        segmentContainerView.addArrangedSubview(rightStackView)
        
        NSLayoutConstraint.activate([
            segmentContainerView.topAnchor.constraint(equalTo: portraitImageView.bottomAnchor, constant: 24),
            segmentContainerView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            segmentContainerView.heightAnchor.constraint(equalToConstant: 30),
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
        
        NSLayoutConstraint.activate([
            imageStackView.topAnchor.constraint(equalTo: segmentContainerView.bottomAnchor, constant: 16),
            imageStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            imageStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            imageStackView.heightAnchor.constraint(equalToConstant: 160)
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
    
    private func createInfoRow(label: String, value: String) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        let labelView = UILabel()
        labelView.text = label
        labelView.textColor = .lightGray
        labelView.font = UIFont.systemFont(ofSize: 14)
        labelView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(labelView)
        
        let valueView = UILabel()
        valueView.text = value
        valueView.textColor = .white
        valueView.font = UIFont.systemFont(ofSize: 14)
        valueView.textAlignment = .left
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
        
        return containerView
    }
    
    // MARK: - Populate Data
    private func populateData() {
        guard let data = mrzData else { return }
        
        // Name
        nameLabel.text = "\(data.firstName) \(data.lastName)"
        
        // Sub Info
        let genderText = data.sex.capitalized
        let ageText = "\(data.age) years old"
        subInfoLabel.text = "\(genderText), \(ageText)\nExpiry: \(data.dateOfExpire)"
        
        // Portrait Image - use passed image if available, otherwise use default "user" image
        if let portrait = portraitImage {
            portraitImageView.image = portrait
        } else {
            portraitImageView.image = UIImage(named: "user")
        }
        
        // Document Images
        updateDocumentImages()
        
        // Personal Info
        personalInfoStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        personalInfoStackView.addArrangedSubview(createInfoRow(label: "Given Name", value: data.firstName))
        personalInfoStackView.addArrangedSubview(createInfoRow(label: "Surname", value: data.lastName))
        personalInfoStackView.addArrangedSubview(createInfoRow(label: "Date of Birth", value: data.dateOfBirth))
        personalInfoStackView.addArrangedSubview(createInfoRow(label: "Gender", value: data.sex.capitalized))
        personalInfoStackView.addArrangedSubview(createInfoRow(label: "Nationality", value: data.nationalityRaw))
        
        // Document Info
        documentInfoStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        documentInfoStackView.addArrangedSubview(createInfoRow(label: "Doc. Type", value: data.documentType == "MRTD_TD3_PASSPORT" ? "Passport" : "ID"))
        documentInfoStackView.addArrangedSubview(createInfoRow(label: "Doc. Number", value: data.documentNumber))
        documentInfoStackView.addArrangedSubview(createInfoRow(label: "Expiry Date", value: data.dateOfExpire))
        
        // Raw MRZ Text
        mrzValueLabel.text = data.mrzText
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
        if let error = error {
            let alert = UIAlertController(title: "Save Error", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        } else {
            let successAlert = UIAlertController(title: "Saved!", message: "The image has been saved to your library.", preferredStyle: .alert)
            present(successAlert, animated: true)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                successAlert.dismiss(animated: true)
            }
        }
    }
}
