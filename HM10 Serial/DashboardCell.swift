//
//  DashboardCell.swift
//  Serial
//
//  Created by Philip Plamenov on 16.07.20.
//  Copyright © 2020 Balancing Rock. All rights reserved.
//

import UIKit

class DashboardCell: UITableViewCell {

    @IBOutlet weak var container: UIView!
    @IBOutlet weak var label: UILabel!
    
    lazy var commandsManager = CommandsManager.shared
    private var cellType: CellType?
    
    func setup(with cellType: CellType) {
        selectionStyle = .none
        container.backgroundColor = UIColor(named: "customBlue")
        self.cellType = cellType
        switch cellType {
        case .ignition:
            if !commandsManager.isIgnitionOn {
                label.text = "Ignition on"
            } else {
                label.text = "Ignition off"
                container.backgroundColor = #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
            }
        case .startEngine:
            if !commandsManager.isStarted {
                label.text = "Start engine"
            } else {
                label.text = "Stop engine"
                container.backgroundColor = #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
            }
        case .headlights:
            if !commandsManager.isLightsOn {
                label.text = "Lights on"
            } else {
                label.text = "Lights off"
                container.backgroundColor = #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
            }
        }
    }
    
    enum CellType {
        case ignition
        case startEngine
        case headlights
    }
}

// MARK: Cell Actions

extension DashboardCell {
    func cellAction(completion: (() -> Void)? = nil) {
        switch cellType {
        case .ignition:
            commandsManager.startIgnition()
        case .startEngine:
            commandsManager.startEngine()
        case .headlights:
            commandsManager.headlights { completion?() }
        case .none: return
        }
    }
}
