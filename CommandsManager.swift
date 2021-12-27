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
            serial.sendMessageToDevice("stopEngine")
            self.isStarted = false
            self.isIgnitionOn = false
            return
        }
        
        startIgnition()
        Helper.delay(1) { [weak self] in
            guard let self = self else { return }
            serial.sendMessageToDevice("startEngine")
            self.isStarted = true
            self.isIgnitionOn = true
        }
        
        
    }
    
    func startIgnition() {
        if !isIgnitionOn {
            serial.sendMessageToDevice("ignOn")
            isIgnitionOn = true
        } else {
            serial.sendMessageToDevice("ignOff")
            isIgnitionOn = false
            isStarted = false
        }
    }
    
    func unlock() {
        serial.sendMessageToDevice("unlock")
        Helper.delay(2.3) {
            // fix for e34 double unlock problem, not needed for other cars
            serial.sendMessageToDevice("unlock")
        }
        isLocked = false
        
    }
    func lock() {
        serial.sendMessageToDevice("lock")
        isLocked = true
    }
    
    func headlights(completion: @escaping () -> Void) {
        if !isLightsOn {
            guard isIgnitionOn else {
                serial.sendMessageToDevice("ignOn")
                isIgnitionOn = true
                Helper.delay(1.5) {
                    serial.sendMessageToDevice("lightsOn")
                    self.isLightsOn = true
                    completion()
                }
                return
            }
            
            serial.sendMessageToDevice("lightsOn")
            self.isLightsOn = true
            completion()
            
        } else {
            serial.sendMessageToDevice("lightsOff")
            self.isLightsOn = false
            completion()
        }
    }
}
