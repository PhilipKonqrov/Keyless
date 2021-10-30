//
//  Helper.swift
//  Serial
//
//  Created by Philip Plamenov on 30.10.21.
//  Copyright © 2021 Balancing Rock. All rights reserved.
//

import Foundation
import UIKit

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
