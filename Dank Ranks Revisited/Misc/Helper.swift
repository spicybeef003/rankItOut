//
//  Extensions.swift
//  TieBreakers
//
//  Created by Jiang, Tony on 12/4/17.
//  Copyright © 2017 Jiang, Tony. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import QuartzCore


extension Array where Element: Comparable {
    func containsSameElements(as other: [Element]) -> Bool {
        return self.count == other.count && self.sorted() == other.sorted()
    }
}

extension Array {
    func splitBy(_ chunkSize: Int) -> [[Element]] {
        return stride(from: 0, to: self.count, by: chunkSize).map {
            Array(self[$0..<Swift.min($0 + chunkSize, self.count)])
        }
    }
}

extension URL {
    
    func value(for parameter: String) -> String? {
        
        let queryItems = URLComponents(string: self.absoluteString)?.queryItems
        let queryItem = queryItems?.filter({$0.name == parameter}).first
        let value = queryItem?.value
        
        return value
    }
    
}
extension MutableCollection {
    /// Shuffles the contents of this collection.
    mutating func shuffle() {
        let c = count
        guard c > 1 else { return }
        
        for (firstUnshuffled, unshuffledCount) in zip(indices, stride(from: c, to: 1, by: -1)) {
            let d: IndexDistance = numericCast(arc4random_uniform(numericCast(unshuffledCount)))
            let i = index(firstUnshuffled, offsetBy: d)
            swapAt(firstUnshuffled, i)
        }
    }
}

extension Sequence {
    /// Returns an array with the contents of this sequence, shuffled.
    func shuffled() -> [Element] {
        var result = Array(self)
        result.shuffle()
        return result
    }
    
}

extension Sequence where Iterator.Element: Hashable {
    func unique() -> [Iterator.Element] {
        var alreadyAdded = Set<Iterator.Element>()
        return self.filter { alreadyAdded.insert($0).inserted }
    }
}

extension String {
    var containsWhitespace : Bool {
        return (self.rangeOfCharacter(from: .whitespacesAndNewlines) != nil)
    }
    
    var isContainsLetters : Bool{
        let letters = CharacterSet.letters
        return self.rangeOfCharacter(from: letters) != nil
    }
    
    func separate(every: Int, with separator: String) -> String {
        return String(stride(from: 0, to: Array(self).count, by: every).map {
            Array(Array(self)[$0..<min($0 + every, Array(self).count)])
            }.joined(separator: separator))
    }
    
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: font], context: nil)
        
        return ceil(boundingBox.height)
    }
    
    func width(withConstraintedHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: font], context: nil)
        
        return ceil(boundingBox.width)
    }
}

extension UIViewController {
    func resetDefaults() {
        let defaults = UserDefaults.standard
        let dictionary = defaults.dictionaryRepresentation()
        dictionary.keys.forEach { key in
            defaults.removeObject(forKey: key)
        }
    }
    
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func shake(object: AnyObject!) {
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.07
        animation.repeatCount = 4
        animation.autoreverses = true
        animation.fromValue = NSValue(cgPoint: CGPoint(x: (object?.center.x)! - 10, y: object.center.y))
        animation.toValue = NSValue(cgPoint: CGPoint(x: object.center.x + 10, y: object.center.y))
        object.layer.add(animation, forKey: "position")
    }
    
    func specialShake(object: AnyObject!) {
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.07
        animation.repeatCount = 20
        animation.autoreverses = true
        animation.fromValue = NSValue(cgPoint: CGPoint(x: (object?.center.x)! - 20, y: object.center.y + 20))
        animation.toValue = NSValue(cgPoint: CGPoint(x: object.center.x + 20, y: object.center.y - 20))
        object.layer.add(animation, forKey: "position")
    }
    
    func heavyShake(object: AnyObject!) {
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.07
        animation.repeatCount = 20
        animation.autoreverses = true
        animation.fromValue = NSValue(cgPoint: CGPoint(x: (object?.center.x)! - 50, y: object.center.y + 50))
        animation.toValue = NSValue(cgPoint: CGPoint(x: object.center.x + 50, y: object.center.y - 50))
        object.layer.add(animation, forKey: "position")
    }
    
    func fullRotate(object: AnyObject!) {
        let fullRotation = CABasicAnimation(keyPath: "transform.rotation")
        fullRotation.delegate = self as? CAAnimationDelegate
        fullRotation.fromValue = NSNumber(floatLiteral: 0)
        fullRotation.toValue = NSNumber(floatLiteral: Double(CGFloat.pi * 2))
        fullRotation.duration = 0.4
        fullRotation.repeatCount = 5
        object.layer.add(fullRotation, forKey: "360")
    }
    
    func alert(message: NSString, title: NSString) {
        let alert = UIAlertController(title: title as String, message: message as String, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = self.view
        }
        self.present(alert, animated: true, completion: nil)
    }
    
    func editButton(button: UIButton!, text: String, font: CGFloat) {
        button.setTitle(text, for: .normal)
        button.contentHorizontalAlignment = .center
        button.titleLabel?.font = UIFont(name: "Avenir", size: (Env.iPad ? font * 1.5 : font))
        button.setTitleColor(.white, for: .normal)
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.borderWidth = 2
        button.backgroundColor = UIColor(red: 0.0/255.0, green: 195.0/255.0, blue: 240.0/255.0, alpha: 1)
        //button.backgroundColor = UIColor.clear
        button.layer.cornerRadius = button.frame.height/5
        button.clipsToBounds = true
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.lineBreakMode = .byWordWrapping;
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.5
        view.addSubview(button)
    }
    
    func editLabel(label: UILabel!, text: String) {
        label.text = text
        label.textColor = UIColor.black
        label.textAlignment = .center
        label.font = UIFont(name: "Avenir", size: (Env.iPad ? 24 : 16))
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        view.addSubview(label)
    }
    
    func convertStructures(rank: RankInfoss) -> Rank {
        let thisRank = Rank()
        thisRank.projectName = rank.Rankname
        thisRank.numObj = rank.NumObj
        thisRank.numSubsets = rank.numSubsets
        thisRank.textArray = Array(rank.textArray[0..<thisRank.numObj]) //shorten text array to first #numobj
        thisRank.type = rank.RankType
        thisRank.finalRankTextArray = rank.textArray
        thisRank.uniqueID = rank.uniqueID
        thisRank.dateCreated = Date()
        
        return thisRank
    }
    
    func compareImage(image: UIImage, imageArray: [UIImage]) -> Int {
        let imageData = UIImagePNGRepresentation(image)
        for (index, item) in imageArray.enumerated() {
            let itemData = UIImagePNGRepresentation(item)
            if imageData == itemData {
                print(index)
                return index
            }
        }
        return -1
    }
}

extension UIImage {
    func resizeImage(targetSize: CGSize) -> UIImage {
        let size = self.size
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        let newSize = widthRatio > heightRatio ?  CGSize(width: size.width * heightRatio, height: size.height * heightRatio) : CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        var newImage: UIImage
        
        if #available(iOS 10.0, *) {
            let renderFormat = UIGraphicsImageRendererFormat.default()
            renderFormat.opaque = false
            let renderer = UIGraphicsImageRenderer(size: newSize, format: renderFormat)
            newImage = renderer.image { (context) in
                self.draw(in: rect)
            }
        }
        else {
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            self.draw(in: rect)
            newImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
        }
        
        return newImage
    }
}

extension NSMutableAttributedString {
    @discardableResult func bold(_ text: String, font: CGFloat) -> NSMutableAttributedString {
        let attrs: [NSAttributedStringKey: Any] = [.font: UIFont.boldSystemFont(ofSize: font)]
        let boldString = NSMutableAttributedString(string:text, attributes: attrs)
        append(boldString)
        
        return self
    }
    
    @discardableResult func normal(_ text: String, font: CGFloat) -> NSMutableAttributedString {
        let attrs: [NSAttributedStringKey: Any] = [.font: UIFont.systemFont(ofSize: font)]
        let normal = NSAttributedString(string: text, attributes: attrs)
        append(normal)
        
        return self
    }
    
    @discardableResult func italics(_ text: String, font: CGFloat) -> NSMutableAttributedString {
        let attrs: [NSAttributedStringKey: Any] = [.font: UIFont.italicSystemFont(ofSize: font)]
        let italicsString = NSAttributedString(string: text, attributes: attrs)
        append(italicsString)
        
        return self
    }
        
    func height(withConstrainedWidth width: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, context: nil)
        
        return ceil(boundingBox.height)
    }
    
    func width(withConstrainedHeight height: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, context: nil)
        
        return ceil(boundingBox.width)
    }
}



class Env {
    
    static var iPad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
}
