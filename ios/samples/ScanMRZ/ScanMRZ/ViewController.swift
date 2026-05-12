//
//  ViewController.swift
//  Dynamsoft
//
//  Created by tst on 2024/11/18.
//

import UIKit
import DynamsoftMRZScannerBundle

class ViewController: UIViewController {
    
    let button = UIButton()
    let label = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.isHidden = true
        view.backgroundColor = .white
        setup()
        setupAppearance()
    }
    
    @objc func buttonTapped() {
        let vc = MRZScannerViewController()
        let config = MRZScannerConfig()
        // Initialize the license.
        // The license string here is a trial license. Note that network connection is required for this license to work.
        // You can request an extension via the following link: https://www.dynamsoft.com/customer/license/trialLicense?product=mrz&utm_source=samples&package=ios
        config.license = "DLS2eyJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSJ9"
        // some other settings
        vc.config = config
        
        vc.onScannedResult = { [weak self] result in
            guard let self = self else { return }
            switch result.resultStatus {
            case .finished:
                if let data = result.data {
                    DispatchQueue.main.async {
                        
                        // Create and navigate to ResultViewController
                        let resultVC = ResultViewController()
                        resultVC.mrzData = data
                        resultVC.portraitImage = try? result.getPortraitImage()?.toUIImage()
                        resultVC.primaryDocumentImage = try? result.getDocumentImage(.mrz)?.toUIImage()
                        resultVC.primaryOriginalImage = try? result.getOriginalImage(.mrz)?.toUIImage()
                        resultVC.secondaryDocumentImage = try? result.getDocumentImage(.opposite)?.toUIImage()
                        resultVC.secondaryOriginalImage = try? result.getOriginalImage(.opposite)?.toUIImage()
                        
                        self.navigationController?.pushViewController(resultVC, animated: true)
                    }
                }
            case .canceled:
                DispatchQueue.main.async {
                    self.label.isHidden = false
                    self.label.text = "Scan canceled"
                    self.navigationController?.popViewController(animated: true)
                }
            case .exception:
                DispatchQueue.main.async {
                    self.label.isHidden = false
                    self.label.text = result.errorString
                    self.navigationController?.popViewController(animated: true)
                }
            default:
                break
            }
        }
        self.label.isHidden = true
        DispatchQueue.main.async {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func setup() {
        button.backgroundColor = .black
        button.setTitle("Scan an MRZ", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)
        
        label.numberOfLines = 0
        label.textColor = .black
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 20)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -10),
            button.heightAnchor.constraint(equalToConstant: 50),
            button.widthAnchor.constraint(equalToConstant: 150),
            
            label.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: safeArea.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 30),
            label.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -30)
        ])
    }
    
    func setupAppearance() {
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
