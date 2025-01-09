//
//  ViewController.swift
//  Dynamsoft
//
//  Created by tst on 2024/11/18.
//

import UIKit
import DynamsoftMRZScannerBundle

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let tableView = UITableView()
    let button = UIButton()
    let label = UILabel()
    var data: [(String, String)] = [
        ("Name", ""),
        ("Sex", ""),
        ("Age", ""),
        ("Document Type", ""),
        ("Document Number", ""),
        ("Issuing State", ""),
        ("Nationality", ""),
        ("Date Of Birth(YYYY-MM-DD)", ""),
        ("Date Of Expire(YYYY-MM-DD)", ""),
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isHidden = true
        setup()
    }
    
    @objc func buttonTapped() {
        let vc = MRZScannerViewController()
        let config = MRZScannerConfig()
        config.license = "DLS2eyJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSJ9"
        // some other settings
        vc.config = config
        
        vc.onScannedResult = { [weak self] result in
            guard let self = self else { return }
            switch result.resultStatus {
            case .finished:
                if let data = result.data {
                    self.data = [
                        ("Name", data.firstName + " " + data.lastName),
                        ("Sex", data.sex.capitalized),
                        ("Age", String(data.age)),
                        ("Document Type", data.documentType),
                        ("Document Number", data.documentNumber),
                        ("Issuing State", data.issuingState),
                        ("Nationality", data.nationality),
                        ("Date Of Birth(YYYY-MM-DD)", data.dateOfBirth),
                        ("Date Of Expire(YYYY-MM-DD)", data.dateOfExpire),
                    ]
                    DispatchQueue.main.async {
                        self.label.isHidden = true
                        self.tableView.isHidden = false
                        self.tableView.reloadData()
                    }
                }
            case .canceled:
                DispatchQueue.main.async {
                    self.label.isHidden = false
                    self.tableView.isHidden = true
                    self.label.text = "Scan canceled"
                }
            case .exception:
                DispatchQueue.main.async {
                    self.label.isHidden = false
                    self.tableView.isHidden = true
                    self.label.text = result.errorString
                }
            default:
                break
            }
            DispatchQueue.main.async {
                self.navigationController?.popViewController(animated: true)
            }
        }
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
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.isHidden = true
        view.addSubview(tableView)
        
        label.numberOfLines = 0
        label.textColor = .black
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 20)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Empty list"
        view.addSubview(label)
        
        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -10),
            button.heightAnchor.constraint(equalToConstant: 50),
            button.widthAnchor.constraint(equalToConstant: 150),
            
            tableView.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            tableView.bottomAnchor.constraint(equalTo: button.topAnchor, constant: -10),
            tableView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            
            label.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: safeArea.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 30),
            label.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -30)
        ])
    }
    
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count * 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        let index = indexPath.row / 2
        let isLabel = indexPath.row % 2 == 0
        let (label, value) = data[index]
        
        if isLabel {
            cell.textLabel?.text = label
            cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 16)
            cell.textLabel?.textColor = .black
        } else {
            cell.textLabel?.text = value
            cell.textLabel?.font = UIFont.systemFont(ofSize: 16)
            cell.textLabel?.textColor = .gray
        }
        return cell
    }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.frame.height / (CGFloat(data.count) * 2.0)
    }
}
