import UIKit
import DynamsoftLabelRecognizer
import DynamsoftCodeParser

class PassportResultModel {
    var parsedResultItem: ParsedResultItem?
    var recognizedText: String?
    
    var name: String! = ""
    var gender: String! = ""
    var age: Int! = 0
    var documentNumber: String! = ""
    var issuingState: String! = ""
    var nationality: String! = ""
    var dateOfBirth: String! = ""
    var dateOfExpiry: String! = ""
    var personalNumber: String! = ""
    var primaryIdentifer: String! = ""
    var secondaryIdentifer: String! = ""
    
    func analyzeInfo() -> Void {
        guard let parsedFields = parsedResultItem?.parsedFields else { return  }
        print("parsedFields:\(parsedFields)")
        let primaryIdentifier = parsedFields["primaryIdentifier"] ?? ""
        let secondaryIdentifier = parsedFields["secondaryIdentifier"] ?? ""
        let birthDay = parsedFields["birthDay"] ?? ""
        let birthMonth = parsedFields["birthMonth"] ?? ""
        let birthYear = String(format: "%d", DSToolsManager.shared.calculateYear(year: Int(parsedFields["birthYear"] ?? "") ?? -1, isExpired: false))
        let expiryDay = parsedFields["expiryDay"] ?? ""
        let expiryMonth = parsedFields["expiryMonth"] ?? ""
        let expiryYear = String(format: "%d", DSToolsManager.shared.calculateYear(year: Int(parsedFields["expiryYear"] ?? "") ?? -1, isExpired: true))
        
        
        self.name = primaryIdentifier + "," + secondaryIdentifier
        self.gender = parsedFields["sex"]?.capitalized
        self.age = DSToolsManager.shared.calculateAge(year: Int(birthYear) ?? -1, month: Int(birthMonth) ?? -1, day: Int(birthDay) ?? -1)
        self.documentNumber = parsedFields["passportNumber"] ?? ""
        self.issuingState = parsedFields["issuingState"] ?? ""
        self.nationality = parsedFields["nationality"] ?? ""
        self.dateOfBirth = birthYear + "-" + birthMonth + "-" + birthDay
        self.dateOfExpiry = expiryYear + "-" + expiryMonth + "-" + expiryDay
        self.personalNumber = parsedFields["personalNumber"] ?? ""
        self.primaryIdentifer = primaryIdentifier
        self.secondaryIdentifer = secondaryIdentifier
       
    }
}

class PassportResultViewController: UIViewController {

    var passportResultModel: PassportResultModel!
    
    private var resultListArray: [[String : String]] = []
    
    private lazy var resultTableView: UITableView = {
        let tableView = UITableView.init(frame: self.view.bounds, style: .plain)
        tableView.flashScrollIndicators()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.tableHeaderView = self.tableHeaderView
        tableView.backgroundColor = .clear
        return tableView
    }()
    
    lazy var tableHeaderView: UIView = {
        let headerView = UIView(frame: CGRectMake(0, 0, self.view.width, 0))
        let userInfo = UILabel(frame: CGRectMake(35.0, 20.0, self.view.width - 70.0, 0))
        userInfo.text = String(format: "%@\n%@, Age: %@", passportResultModel.name, passportResultModel.gender, passportResultModel.age != -1 ? String(format: "%ld", passportResultModel.age) : "Unknown")
        userInfo.textColor = .white
        userInfo.font = UIFont.systemFont(ofSize: 20.0)
        userInfo.numberOfLines = 0
        userInfo.sizeToFit()
        headerView.height = userInfo.height + 35.0
        headerView.addSubview(userInfo)
        return headerView
    }()
    
    private lazy var label: UILabel = {
        let label = UILabel()
        label.backgroundColor = .clear
        label.textAlignment = .center
        label.textColor = .init(red: 153 / 255.0, green: 153 / 255.0, blue: 153 / 255.0, alpha: 1.0)
        label.text = "Powered by Dynamsoft"
        label.sizeToFit()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.view.backgroundColor = .init(red: 59 / 255.0, green: 59 / 255.0, blue: 59 / 255.0, alpha: 1.0)
        self.title = "Result"
        analyzeData()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        resetUI()
    }

    func analyzeData() -> Void {
        passportResultModel.analyzeInfo()
        resultListArray = [["Title": "Document Number:", "Content":passportResultModel.documentNumber],
                           ["Title": "Issuing State:", "Content":passportResultModel.issuingState],
                           ["Title": "Nationality:", "Content":passportResultModel.nationality],
                           ["Title": "Date of Birth(YYYY-MM-DD):", "Content":passportResultModel.dateOfBirth],
                           ["Title": "Date of Expiry(YYYY-MM-DD):", "Content":passportResultModel.dateOfExpiry],
                           ["Title": "Personal Number:", "Content":passportResultModel.personalNumber],
                           ["Title": "Primary Identifier(s):", "Content":passportResultModel.primaryIdentifer],
                           ["Title": "Secondary Identifier(s):", "Content":passportResultModel.secondaryIdentifer],
                           
        ]
    }
    
    func setupUI() -> Void {
        self.view.addSubview(resultTableView)
        self.view.addSubview(label)
    }
    
    private func resetUI() -> Void {
        label.centerXAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        label.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -35).isActive = true
    }
}

extension PassportResultViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resultListArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let dataInfo = self.resultListArray[indexPath.row]
        let title = dataInfo["Title"] ?? ""
        let subTitle = dataInfo["Content"] ?? ""
    
        let identifier = "DCPResultCell"
        var cell = tableView.dequeueReusableCell(withIdentifier: identifier)
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: identifier)
        }
        cell?.selectionStyle = .none
        cell?.textLabel?.text = title
        cell?.textLabel?.textColor = .init(red: 170 / 255.0, green: 170 / 255.0, blue: 170 / 255.0, alpha: 1.0)
        cell?.textLabel?.font = UIFont.boldSystemFont(ofSize: 16.0)
        cell?.detailTextLabel?.text = subTitle
        cell?.detailTextLabel?.textColor = .white.withAlphaComponent(1.0)
        cell?.detailTextLabel?.font = UIFont.systemFont(ofSize: 16.0)
        cell?.detailTextLabel?.numberOfLines = 0
        cell?.backgroundColor = .clear
        cell?.indentationLevel = 1
        cell?.indentationWidth = 18
        return cell!
    }
}
