
import Foundation
import UIKit

class DSToolsManager {
    static let shared = DSToolsManager()
    
    let timezone = NSTimeZone.system
}

// MARK: - Timestamp convert.
extension DSToolsManager {
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
}

// MARK: - Text suitable.
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
