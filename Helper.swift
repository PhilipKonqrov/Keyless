//
//  Helper.swift
//  Serial
//
//  Created by Philip Plamenov on 30.10.21.
//  Copyright © 2021 Balancing Rock. All rights reserved.
//

import Foundation
import UIKit

class Helper {
    class func delay(_ delay:Double, closure:@escaping ()->()) {
        let when = DispatchTime.now() + delay
        DispatchQueue.main.asyncAfter(deadline: when, execute: closure)
    }
}

protocol Loadable where Self: UIViewController {
    var loader: UIAlertController? { get set }
}
extension Loadable {
    
    func showLoader(withText: String? = nil, dismissAfter: Int? = nil) {
        
        let alert = UIAlertController(title: nil, message: withText ?? "Connecting...", preferredStyle: .alert)

        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = .large
        loadingIndicator.startAnimating();

        alert.view.addSubview(loadingIndicator)
        loader = alert
        self.present(alert, animated: true, completion: nil)
        
        if let dismissTime = dismissAfter {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(dismissTime)) {
                self.dismissLoader()
            }
        }
    }
    
    func dismissLoader() {
        loader?.dismiss(animated: true, completion: nil)
    }
}

extension UIButton {

    func centerTextAndImage(spacing: CGFloat) {
        let insetAmount = spacing / 2
        let isRTL = UIView.userInterfaceLayoutDirection(for: semanticContentAttribute) == .rightToLeft
        if isRTL {
            self.imageEdgeInsets = UIEdgeInsets(top: 0, left: insetAmount, bottom: 0, right: -insetAmount)
            self.titleEdgeInsets = UIEdgeInsets(top: 0, left: -insetAmount, bottom: 0, right: insetAmount)
            self.contentEdgeInsets = UIEdgeInsets(top: 0, left: -insetAmount, bottom: 0, right: -insetAmount)
        } else {
            self.imageEdgeInsets = UIEdgeInsets(top: 0, left: -insetAmount, bottom: 0, right: insetAmount)
            self.titleEdgeInsets = UIEdgeInsets(top: 0, left: insetAmount, bottom: 0, right: -insetAmount)
            self.contentEdgeInsets = UIEdgeInsets(top: 0, left: insetAmount, bottom: 0, right: insetAmount)
        }
    }
}

extension UIImage {

    func alpha(_ value:CGFloat) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(at: CGPoint.zero, blendMode: .normal, alpha: value)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
}

extension UIViewController {
    
    /// Presents alert box with one button without action.
    func presentSimpleAlert(with title: String, message: String, buttonTitle: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: buttonTitle, style: UIAlertAction.Style.default, handler: { action -> Void in self.dismiss(animated: true, completion: nil) }))
        present(alert, animated: true, completion: nil)
    }
}
