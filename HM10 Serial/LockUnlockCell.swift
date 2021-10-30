//
//  LockUnlockCell.swift
//  Serial
//
//  Created by Philip Plamenov on 30.10.21.
//  Copyright © 2021 Balancing Rock. All rights reserved.
//

import UIKit

class LockUnlockCell: UITableViewCell {
    @IBOutlet weak var lock: UIButton!
    @IBOutlet weak var unlock: UIButton!
    
    weak var dashboardReference: HomeVC?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        lock.setupButton(buttonStyle: .lock)
        unlock.setupButton(buttonStyle: .unlock)
    }
    
    @IBAction func lock(_ sender: Any) {
        dashboardReference?.lockOverride = true
        dashboardReference?.lock()
    }
    @IBAction func unlock(_ sender: Any) {
        dashboardReference?.lockOverride = true
        dashboardReference?.unlock()
    }
    
}

fileprivate extension UIButton {
    func setupButton(buttonStyle: ButtonStyle) {
        setTitleColor(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.8013245033), for: .normal)
        tintColor = .white
        let buttonIconConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold, scale: .large)
        let buttonIco: UIImage?
        
        switch buttonStyle {
        case .lock:
            buttonIco = UIImage(systemName: "lock.open.fill", withConfiguration: buttonIconConfig)?.alpha(0.8).withRenderingMode(.alwaysTemplate)
        case .unlock:
            buttonIco = UIImage(systemName: "lock.fill", withConfiguration: buttonIconConfig)?.alpha(0.8).withRenderingMode(.alwaysTemplate)
        }
        setImage(buttonIco, for: .normal)
        centerTextAndImage(spacing: 10)
    }
    
    enum ButtonStyle {
        case lock
        case unlock
    }
}
