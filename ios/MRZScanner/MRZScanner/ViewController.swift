import UIKit

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true;
    }
    
    @IBAction func onClick(_ sender: Any) {
        let vc = CameraViewController()
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
