
import UIKit

class BaseViewController: UIViewController {
    
    lazy var enterpriseInfo: UILabel = {
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
        self.view.addSubview(enterpriseInfo)
        
        DSToolsManager.shared.clearCaches()
        NSLayoutConstraint.activate([
            enterpriseInfo.centerXAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor),
            enterpriseInfo.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -35)
        ])
    }

}


