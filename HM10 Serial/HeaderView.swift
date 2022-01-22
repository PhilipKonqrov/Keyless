//
//  HeaderView.swift
//  Keyless
//
//  Created by Philip Plamenov on 26.12.21.
//  Copyright © 2021 Balancing Rock. All rights reserved.
//

import UIKit
import Combine

class HeaderView: UIView {
    @IBOutlet weak var mainStack: UIStackView?
    @IBOutlet weak var connectionStatus: UIStackView?
    @IBOutlet weak var deviceName: UIStackView?
    @IBOutlet weak var signalStrength: UIStackView?
    
    @IBOutlet weak var connectionStatusLabel: UILabel?
    @IBOutlet weak var connectionStatusView: UIView?
    
    @IBOutlet weak var deviceNameLabel: UILabel?
    
    @IBOutlet weak var signalStrengthLabel: UILabel?
    
    private var connectionStatusCancellable: AnyCancellable?
    private var rssiCancellable: AnyCancellable?
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        connectionStatusCancellable = serial.serialConnectionStatus
            .receive(on: RunLoop.main)
            .sink { completion in
                switch completion {
                case .finished:
                    print("finished")
                case .failure(let error):
                    print(error)
                }
            } receiveValue: { [weak self] (peripheral, connectionStatus) in
                switch connectionStatus {
                case .connected:
                    self?.connectionStatusLabel?.text = "Status: Connected"
                    self?.connectionStatusView?.backgroundColor = .systemGreen
                    self?.deviceNameLabel?.text = "Device name: \(peripheral.name ?? "Unknown")"
                    self?.rssiCancellable = serial.$rssiSignal
                        .receive(on: RunLoop.main)
                        .sink { [weak self] signal in
                            self?.signalStrengthLabel?.text = "Signal strength: \(serial.rssiSignal)dBm"
                        }
                case .disconnected:
                    self?.rssiCancellable?.cancel()
                    self?.connectionStatusLabel?.text = "Status: Disconnected"
                    self?.connectionStatusView?.backgroundColor = .systemRed
                    self?.signalStrengthLabel?.text = "Signal strength: Unknown"
                case .failed:
                    self?.rssiCancellable?.cancel()
                    self?.connectionStatusLabel?.text = "Status: Failure"
                    self?.connectionStatusView?.backgroundColor = .systemRed
                    self?.signalStrengthLabel?.text = "Signal strength: Unknown"
                }
            }
    }
}


