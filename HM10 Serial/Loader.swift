//
//  Loader.swift
//  Serial
//
//  Created by Philip Plamenov on 24.10.21.
//  Copyright © 2021 Balancing Rock. All rights reserved.
//

import UIKit

class Loader: UIView {
    @IBOutlet weak private var container: UIView!
    @IBOutlet weak private var activity: UIActivityIndicatorView!
    @IBOutlet weak private var textLabel: UILabel!
    
    var loaderText: String? {
        didSet {
            textLabel.text = loaderText
        }
    }
    
    override func awakeFromNib() {
        container.layer.cornerRadius = 10
        container.layer.masksToBounds = false
        activity.startAnimating()
    }
    
}

protocol Loadable: AnyObject {
    var loader: UIView? { get set }
}

extension Loadable where Self: UIViewController {
    func presentLoader(with text: String? = nil) {
        let nib = UINib(nibName: "Loader", bundle: nil)
        let loaderView = nib.instantiate(withOwner: self, options: nil).first as! Loader
        if let text = text {
            loaderView.loaderText = text
        }
//        loaderView.frame = CGRect(x: view.frame.midX - (loaderView.frame.width/2), y: UIScreen.main.bounds.midY - (loaderView.frame.height/2), width: loaderView.frame.width, height: loaderView.frame.height)
        loader = loaderView
        view.addSubview(loaderView)
        
    }
    
    func dismissLoader() {
        loader?.removeFromSuperview() 
    }
}
