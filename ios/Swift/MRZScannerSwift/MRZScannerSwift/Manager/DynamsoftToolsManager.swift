//
//  DynamsoftToolsManager.swift
//  HelloWorldSwift

import Foundation
import UIKit

class DynamsoftToolsManager {
    static let shared = DynamsoftToolsManager()
    
    func calculateWidth(withText string: String, font: UIFont, componentHeight:CGFloat) -> CGFloat {
        if string.count == 0 {
            return 0
        }
        let dic = [NSAttributedString.Key.font:font]
        let frame = (string as NSString).boundingRect(with: CGSize(width: 10000, height: componentHeight), options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: dic, context: nil)
        return frame.size.width
    }
    
    func calculateHeight(withText string: String, font: UIFont, componentWidth:CGFloat) -> CGFloat {
        if string.count == 0 {
            return 0
        }
        let dic = [NSAttributedString.Key.font:font]
        let frame = (string as NSString).boundingRect(with: CGSize(width: componentWidth, height: 10000), options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: dic, context: nil)
        return frame.size.height
    }
    
}
