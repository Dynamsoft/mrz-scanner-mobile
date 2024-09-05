import UIKit
import DynamsoftLabelRecognizer
import DynamsoftCodeParser

class MRZResultModel {
    var parsedResultItem: ParsedResultItem?
    var recognizedText: String?
    
    var documentType: String! = ""
    var name: String! = ""
    var gender: String! = ""
    var age: Int! = 0
    var documentNumber: String! = ""
    var issuingState: String! = ""
    var nationality: String! = ""
    var dateOfBirth: String! = ""
    var dateOfExpiry: String! = ""
    
    // Assemble the parsed info from the ParsedResultItem.
    // Parsed fields are stored in a Dictionary with field name as the key and field value as the value.
    // The following code shows how to get the parsed field values.
    func determineWhetherIsLegal() -> Bool {
        guard let parsedFields = parsedResultItem?.parsedFields else { return false }
        guard let documentType = parsedResultItem?.codeType else { return false }
        var isLegal = true
        if parsedFields["birthDay"] == nil ||
            parsedFields["birthMonth"] == nil ||
            parsedFields["birthYear"] == nil ||
            parsedFields["expiryDay"] == nil ||
            parsedFields["expiryMonth"] == nil ||
            parsedFields["expiryYear"] == nil ||
            parsedFields["sex"] == nil ||
            parsedFields["issuingState"] == nil ||
            parsedFields["nationality"] == nil ||
            parsedFields["primaryIdentifier"] == nil ||
            parsedFields["secondaryIdentifier"] == nil {
            isLegal = false
        }
        
        let birthDay = parsedFields["birthDay"] ?? ""
        let birthMonth = parsedFields["birthMonth"] ?? ""
        let birthYear = String(format: "%d", DSToolsManager.shared.calculateYear(year: Int(parsedFields["birthYear"] ?? "") ?? -1,
                                                                                 isExpired: false))
        let expiryDay = parsedFields["expiryDay"] ?? "--"
        let expiryMonth = parsedFields["expiryMonth"] ?? "--"
        let expiryYear = String(format: "%d", DSToolsManager.shared.calculateYear(year: Int(parsedFields["expiryYear"] ?? "----") ?? -1,
                                                                                  isExpired: true))

        self.gender = parsedFields["sex"]?.capitalized ?? ""
        self.age = DSToolsManager.shared.calculateAge(year: Int(birthYear) ?? -1,
                                                      month: Int(birthMonth) ?? -1,
                                                      day: Int(birthDay) ?? -1)
        self.issuingState = parsedFields["issuingState"] ?? ""
        self.nationality = parsedFields["nationality"] ?? ""
        self.dateOfBirth = birthYear + "-" + birthMonth + "-" + birthDay
        self.dateOfExpiry = expiryYear + "-" + expiryMonth + "-" + expiryDay
        
        switch documentType {
        case "MRTD_TD1_ID", "MRTD_TD2_ID":
            self.name = parsedFields["name"] ?? ""
            self.documentNumber = parsedFields["documentNumber"] ?? ""
            self.documentType = "ID"
            break
        case "MRTD_TD3_PASSPORT":
            let primaryIdentifier = parsedFields["primaryIdentifier"] ?? ""
            let secondaryIdentifier = parsedFields["secondaryIdentifier"] ?? ""
            if primaryIdentifier != "" && secondaryIdentifier != "" {
                self.name = secondaryIdentifier + " " + primaryIdentifier
            } else if primaryIdentifier != "" && secondaryIdentifier == "" {
                self.name = primaryIdentifier
            } else if primaryIdentifier == "" && secondaryIdentifier != "" {
                self.name = secondaryIdentifier
            } else {
                self.name = ""
            }
            self.documentNumber = parsedFields["passportNumber"] ?? ""
            self.documentType = "Passport"
            break
        default:
            self.documentNumber = ""
            self.name = ""
            self.documentType = ""
        }
        
        if self.name == "" ||  self.documentNumber == "" ||  self.documentType == "" {
            isLegal = false
        }
        
        return isLegal
    }
    
}

class MRZResultViewController: BaseViewController {

    var mrzResultModel: MRZResultModel!
    
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
        userInfo.text = String(format: "%@\n%@, Age: %@", mrzResultModel.name, mrzResultModel.gender, mrzResultModel.age != -1 ? String(format: "%ld", mrzResultModel.age) : "Unknown")
        userInfo.textColor = .white
        userInfo.font = UIFont.systemFont(ofSize: 20.0)
        userInfo.numberOfLines = 0
        userInfo.sizeToFit()
        headerView.height = userInfo.height + 35.0
        headerView.addSubview(userInfo)
        return headerView
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
    }

    func analyzeData() -> Void {
        resultListArray = [["Title": "Document Type", "Content":mrzResultModel.documentType],
                           ["Title": "Document Number:", "Content":mrzResultModel.documentNumber],
                           ["Title": "Issuing State:", "Content":mrzResultModel.issuingState],
                           ["Title": "Nationality:", "Content":mrzResultModel.nationality],
                           ["Title": "Date of Birth(YYYY-MM-DD):", "Content":mrzResultModel.dateOfBirth],
                           ["Title": "Date of Expiry(YYYY-MM-DD):", "Content":mrzResultModel.dateOfExpiry],
                           
        ]
    }
    func setupUI() -> Void {
        self.view.addSubview(resultTableView)
        self.view.bringSubviewToFront(enterpriseInfo)
    }
}

extension MRZResultViewController: UITableViewDelegate, UITableViewDataSource {
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
