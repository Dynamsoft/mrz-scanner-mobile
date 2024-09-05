
import Foundation
import UIKit

class DSToolsManager {
    static let shared = DSToolsManager()
    
    let timezone = NSTimeZone.system
    
    var tipTopMargin = kNavigationBarFullHeight + 100.0
    
    var tipRecordList: [DSTipView] = []
}

// MARK: - Timestamp converter.
extension DSToolsManager {
    public func clearCaches() -> Void {
        tipTopMargin = kNavigationBarFullHeight + 100.0
        tipRecordList.removeAll()
    }
    
    public func getCurrentSTimestamp() -> Int {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss sss"

      
        let timeZone =  timezone
        formatter.timeZone = timeZone as TimeZone?
        let datenow = Date()
        let timeSp = NSNumber(value: datenow.timeIntervalSince1970).intValue
        return timeSp
    }
    
    public func getCurrentMsTimestamp() -> Int {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        let timeZone =  timezone
        formatter.timeZone = timeZone as TimeZone?
        let datenow = Date()
        let timeSp = NSNumber(value: datenow.timeIntervalSince1970 * 1000).intValue
        return timeSp
    }
    
    public func switchToTimeString(with timestamp: Int, format: String = "yyyy-MM-dd HH:mm:ss") -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.dateFormat = format
        
        let timeZone = timezone
        formatter.timeZone = timeZone as TimeZone?
        
        let specifyDate = Date.init(timeIntervalSince1970: TimeInterval(timestamp))
        let timeString = formatter.string(from: specifyDate)
        return timeString
    }
    
    public func switchToMSTimeString(with timestamp: Int, format: String = "yyyy-MM-dd HH:mm:ss SSS") -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.dateFormat = format
        
        let timeZone = timezone
        formatter.timeZone = timeZone as TimeZone?
        
        let specifyDate = Date.init(timeIntervalSince1970: TimeInterval(timestamp) / 1000.0)
        let timeString = formatter.string(from: specifyDate)
        return timeString
    }
    
    func calculateAge(year: Int, month: Int, day: Int) -> Int {
        guard year != -1, month != -1, day != -1 else {
            return -1
        }

        let birthYear = self.calculateYear(year: year, isExpired: false)
        let birthdayComponents = DateComponents(calendar: Calendar.current, year: birthYear, month: month, day: day)
        
        if let birthdayDate = birthdayComponents.date {
            let currentDate = Date()
            let calendar = Calendar.current
            let ageComponents = calendar.dateComponents([.year, .month, .day], from: birthdayDate, to: currentDate)
            return ageComponents.year ?? 0
        }
        return 0
    }
    
    func calculateYear(year: Int, isExpired: Bool) -> Int {
        guard year != -1 else {
            return -1
        }
        
        var birthYear = year
        
        if year < 100 {
            let currentYear = Int(DSToolsManager.shared.switchToMSTimeString(with: DSToolsManager.shared.getCurrentMsTimestamp(), format: "yyyy")) ?? 0
            if isExpired {
                birthYear = 2000 + year;
            } else {
                if year > (currentYear - 2000) {
                    birthYear = 1900 + year
                } else {
                    birthYear = 2000 + year
                }
            }
            
        }
        return birthYear;
    }
}

// MARK: - Alert.
extension DSToolsManager {

    func addAlertView(to target: UIViewController,
                      title: String = "",
                      content: String,
                      actionTitle: String = "OK",
                      completion: @escaping () -> Void) -> Void {
        DispatchQueue.main.async {
            let alertVC = UIAlertController.init(title: title, message: content, preferredStyle: .alert)
            let action = UIAlertAction.init(title: actionTitle, style: .default) { action in
                completion()
            }
            alertVC.addAction(action)
            target.present(alertVC, animated: true)
        }
    }
    
    func addTipView(to target: UIViewController,
                      tip: String = "") -> Void {
        DispatchQueue.main.async {
            let tipVerticalMargin = 10.0
            
            var isNecessaryRemoveAll = true
            for tipRecordList in self.tipRecordList {
                if tipRecordList.tipText.contains("License initialization failed:") {
                    isNecessaryRemoveAll = false
                    break
                }
            }
            if isNecessaryRemoveAll == true {
                for tipRecordList in self.tipRecordList {
                    tipRecordList.removeFromSuperview()
                }
                self.clearCaches()
            } else {
                if self.tipRecordList.count == 2 {
                    self.tipTopMargin = self.tipTopMargin - self.tipRecordList[1].height - tipVerticalMargin
                    self.tipRecordList[1].removeFromSuperview()
                    self.tipRecordList.remove(at: 1)
                }
            }
           
            let tipFrame = CGRectMake(minTipLeadingMargin, self.tipTopMargin, maxTipMaskWidth, 0)
            let tipView = DSTipView(frame: tipFrame, tipText: tip)
            target.view.addSubview(tipView)
            self.tipTopMargin = self.tipTopMargin + tipView.height + tipVerticalMargin
            self.tipRecordList.append(tipView)
        }
    }
    
    func constructParsedTipContentWith(recognizedText: String) -> NSAttributedString {
        let tipPrefixAttribute = NSAttributedString(string: parseFailedTip, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14.0), NSAttributedString.Key.foregroundColor: UIColor.red])
        let tipAttribute = NSAttributedString(string: String(format: "The MRZ text is :\n%@", recognizedText), attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14.0), NSAttributedString.Key.foregroundColor: UIColor.white])
        let content = NSMutableAttributedString()
        content.append(tipPrefixAttribute)
        content.append(tipAttribute)
        return content
    }
    
}

// MARK: - Text box adaptation.
extension DSToolsManager {
    func calculateWidth(with text: String, font: UIFont, componentHeight: CGFloat) -> CGFloat {
        guard text.count != 0 else {
            return 0.0
        }
        let dic = [NSAttributedString.Key.font: font]
        let frame = (text as NSString).boundingRect(with:  CGSize(width: 10000, height: componentHeight), options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: dic, context: nil)
        return frame.size.width
    }
    
    func calculateHeight(with text: String, font: UIFont, componentWidth: CGFloat) -> CGFloat {
        guard text.count != 0 else {
            return 0.0
        }
        let dic = [NSAttributedString.Key.font: font]
        let frame = (text as NSString).boundingRect(with: CGSize(width: componentWidth, height: 10000), options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: dic, context: nil)
        return frame.size.height
    }
}

// MARK: - TipView.
let minTipLeadingMargin = 22.0

let maxTipMaskWidth = kScreenWidth - 2 * minTipLeadingMargin

let tipLeadingMargin = 34.0

let tipTrailingMargin = 11.0

let tipMaxWidth = maxTipMaskWidth - tipLeadingMargin - tipTrailingMargin

let tipTopMargin = 10.0

class DSTipView: UIView {
    
    var tipText: String = ""
    
    lazy var maskBGV: UIView = {
        let left = 0.0
        let top = 0.0
        let width = maxTipMaskWidth
        let height = 0.0
        let view = UIView(frame: CGRectMake(left, top, width, height))
        view.backgroundColor = .black.withAlphaComponent(0.2)
        return view
    }()
    
    lazy var icon: UIImageView = {
        let left = 10.0
        let top = 10.0
        let width = 16.0
        let height = 16.0
        let imageV = UIImageView(frame: CGRectMake(left, top, width, height))
        imageV.image = UIImage(named: "tip-attention")
        return imageV
    }()
    
    lazy var tip: UILabel = {
        let font = UIFont.systemFont(ofSize: 14.0)
        let left = tipLeadingMargin
        let top = tipTopMargin
        var width = tipMaxWidth
        let height = DSToolsManager.shared.calculateHeight(with: tipText, font: font, componentWidth: tipMaxWidth)
        if height <= 20.0 {
            width = DSToolsManager.shared.calculateWidth(with: tipText, font: font, componentHeight: 14.0)
        }
        let label = UILabel(frame: CGRectMake(left, top, width, height))
        label.backgroundColor = .clear
        label.numberOfLines = 0
        label.textAlignment = .left
        label.font = font
        label.textColor = .white
        label.text = tipText
        return label
    }()
    
    init(frame: CGRect, tipText: String) {
        super.init(frame: frame)
        self.tipText = tipText
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() -> Void {
        addSubview(maskBGV)
        maskBGV.addSubview(icon)
        maskBGV.addSubview(tip)
        
        maskBGV.width = tip.width + tipLeadingMargin + tipTrailingMargin
        maskBGV.height = tip.height + tipTopMargin + tipTopMargin
        self.height = maskBGV.height
    }
}
