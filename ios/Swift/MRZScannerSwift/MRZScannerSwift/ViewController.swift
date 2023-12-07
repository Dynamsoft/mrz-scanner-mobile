//
//  ViewController.swift
//  MRZScannerSwift

import UIKit

class ViewController: BaseViewController, MRZResultListener {

    var mrzRecognizer: DynamsoftMRZRecognizer!
    var cameraEnhancer: DynamsoftCameraEnhancer!
    var dceView: DCECameraView!
    
    var currentInterfaceOrientation: UIInterfaceOrientation = .portrait
    var isOrientationUseful: Bool = true
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.tintColor = .white
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
        self.navigationController?.navigationBar.barTintColor = UIColor(red: 59.003 / 255.0, green: 61.9991 / 255.0, blue: 69.0028 / 255.0, alpha: 1)
        
        mrzRecognizer.startScanning()
        isOrientationUseful = true
        
        switch currentInterfaceOrientation {
       
        case .portrait:
            UIDevice.setOrientation(.portrait)
       
        case .landscapeRight:
            UIDevice.setOrientation(.landscapeRight)
       
        default:
            break
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isOrientationUseful = false
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.view.backgroundColor = .white
        self.title = "MRZ Scanner"
        
        NotificationCenter.default.addObserver(self, selector: #selector(orientationChange), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
        configureMRZ()
    }
    
    func configureMRZ() -> Void {
        mrzRecognizer = DynamsoftMRZRecognizer.init()
        
        dceView = DCECameraView.init(frame: self.view.bounds)
        cameraEnhancer = DynamsoftCameraEnhancer.init(view: dceView)
        self.view.addSubview(dceView)
        cameraEnhancer.open()
        
        mrzRecognizer.setImageSource(cameraEnhancer)
        mrzRecognizer.setMRZResultListener(self)
        mrzRecognizer.startScanning()
        
        let region = iRegionDefinition.init()
        region.regionLeft = 5
        region.regionRight = 95
        region.regionTop = 40
        region.regionBottom = 60
        region.regionMeasuredByPercentage = 1
        try? cameraEnhancer.setScanRegion(region)
    }
    
    // MARK: - MRZRessultListener
    func mrzResultCallback(_ frameId: Int, imageData: iImageData, result: iMRZResult?) {
        if let mrzResult = result {
            mrzRecognizer.stopScanning()
            if isOrientationUseful {
                let mrzResultVC = MRZResultViewController.init()
                mrzResultVC.mrzResult = mrzResult
                self.navigationController?.pushViewController(mrzResultVC, animated: true)
            }
        }
    }
    
    // MARK: - Orientation
    
    @objc func orientationChange() -> Void {
        
        guard isOrientationUseful == true else {
            return
        }
        
        let orientation = UIApplication.shared.statusBarOrientation
        currentInterfaceOrientation = orientation
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.portrait, .landscapeRight]
    }
    
    override var shouldAutorotate: Bool {
        get {true}
    }

}

