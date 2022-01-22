//
//  CommandsManager.swift
//  Keyless
//
//  Created by Philip Plamenov on 26.12.21.
//  Copyright © 2021 Balancing Rock. All rights reserved.
//

import Foundation
class CommandsManager {
    
    var isStarted = false
    var isIgnitionOn = false
    var isLightsOn = false
    var isLocked = true
    var lockOverride = false
    
    static let shared = CommandsManager()
    private init() {}
}

extension CommandsManager {
    func startEngine() {
        
        if isStarted {
            serial.sendMessageToDevice("16#1") // Ignition cut-off
            self.isStarted = false
            self.isIgnitionOn = false
            return
        }
        
        startIgnition()
        Helper.delay(1) { [weak self] in
            guard let self = self else { return }
            serial.sendMessageToDevice("17#0") // 17 is starter pin
            self.isStarted = true
            self.isIgnitionOn = true
        }
        
        
    }
    
    func startIgnition() {
        if !isIgnitionOn {
            serial.sendMessageToDevice("16#0")
            isIgnitionOn = true
        } else {
            serial.sendMessageToDevice("16#1")
            isIgnitionOn = false
            isStarted = false
        }
    }
    
    func unlock() {
        serial.sendMessageToDevice("18#0") // 18 is the unlock pin
        Helper.delay(2.3) {
            // fix for e34 double unlock problem, not needed for other cars
            serial.sendMessageToDevice("18#0")
        }
        isLocked = false
        
    }
    func lock() {
        serial.sendMessageToDevice("18#1")
        isLocked = true
    }
    
    func headlights(completion: @escaping () -> Void) {
        if !isLightsOn {
            guard isIgnitionOn else {
                serial.sendMessageToDevice("16#0")
                isIgnitionOn = true
                Helper.delay(1.5) {
                    serial.sendMessageToDevice("21#0") // 21 is headlights pin
                    self.isLightsOn = true
                    completion()
                }
                return
            }
            
            serial.sendMessageToDevice("21#0")
            self.isLightsOn = true
            completion()
            
        } else {
            serial.sendMessageToDevice("21#1")
            self.isLightsOn = false
            completion()
        }
    }
}
