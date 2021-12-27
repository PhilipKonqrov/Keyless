//
//  NewController.swift
//  Serial
//
//  Created by Philip Plamenov on 23.06.20.
//  Copyright © 2020 Balancing Rock. All rights reserved.
//

import UIKit
import CoreBluetooth
class HomeVC: UIViewController, Loadable {
    
    
    @IBOutlet weak var tableView: UITableView!
    
    //MARK: Variables
    
    /// The peripherals that have been discovered (no duplicates and sorted by asc RSSI)
    var peripherals: [(peripheral: CBPeripheral, RSSI: Float)] = []
    
    var isConnecting = false
    var isConnected = false
    var lockOverride = false
//    let remoteStarterId = "637D5AC5-3EED-DAE7-8E10-FA550CA6877E"
    let remoteStarterId = "39B01AB6-EABC-3B29-5B46-7D92A28DFF9C"
    var refreshControl = UIRefreshControl()
    var selectedPeripheral: CBPeripheral?
    var loader: UIAlertController?
    
    var commandsManager = CommandsManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        // init serial
        serial = BluetoothSerial(delegate: self)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.serialDidReceiveString(_:)), name: NSNotification.Name(rawValue: "bleCommandReceived"), object: nil)
        
        Helper.delay(1) {
            self.scanBT()
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        Helper.delay(3) { [weak self] in
            guard let self = self else { return }
            let alert = UIAlertController(title: "Scanning...", message: nil, preferredStyle: .actionSheet)
            
            alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler:{ (UIAlertAction)in
                print("User click Dismiss button")
            }))
            
            for peripheral in self.peripherals {
                alert.addAction(UIAlertAction(title: peripheral.peripheral.name, style: .default , handler: { [weak self] _ in
                    serial.stopScan()
                    serial.connectToPeripheral(peripheral.peripheral)
                    self?.dismiss(animated: true)
                }))
            }
            
            self.present(alert, animated: true, completion: nil)
            
            Helper.delay(5) {
                self.dismiss(animated: true)
            }
        }
    }
    
    func scanBT() {
        if serial.centralManager.state != .poweredOn {
            title = "Bluetooth not turned on"
            return
        }
        
        // start scanning and schedule the time out
        serial.startScan()
        
    }
    
    
    /// Should be called 10s after we've begun connecting
    func connectTimeOut() {
        
        // don't if we've already connected
        if let _ = serial.connectedPeripheral {
            return
        }
        
        dismissLoader()
        showLoader(withText: "Failed to connect", dismissAfter: 2)
    }
    
    @IBAction func connect(_ sender: Any) {
        performSegue(withIdentifier: "scanBT", sender: self)
    }
    
    
    
    func serialDidReadRSSI(_ rssi: NSNumber) {
        print("Signal rssi: \(rssi)")
        
        // Disable proximity lock unlock function for now
        
//        if rssi.intValue < -90 && !lockOverride {
//            if isLocked { return }
//            lock()
//        } else if rssi.intValue > -85 && !lockOverride {
//            if !isLocked { return }
//            unlock()
//        }
    }
    
    func connect() {
        if isConnecting { return }
        isConnecting = true
        guard let peripheral = selectedPeripheral else { return }
        serial.stopScan()
        serial.connectToPeripheral(peripheral)
        Helper.delay(10) {
            self.connectTimeOut()
        }
    }
    
    
    
    private func readRssiTimer() {
         Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { (Timer) in
             serial?.readRSSI()
         })
     }
    
    
    
}
extension HomeVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            return defaultCell(with: indexPath, and: .ignition)
        case 1:
            return defaultCell(with: indexPath, and: .startEngine)
        case 2:
            let doorUnlockCell = tableView.dequeueReusableCell(withIdentifier: "LockUnlockCell", for: indexPath) as! LockUnlockCell
            doorUnlockCell.selectionStyle = .none
            doorUnlockCell.dashboardReference = self
            return doorUnlockCell
        case 3:
            return defaultCell(with: indexPath, and: .headlights)
        default:
            return UITableViewCell()
        }
    }
    
    private func defaultCell(with index: IndexPath, and cellType: DashboardCell.CellType) -> DashboardCell {
        let defaultCell = tableView.dequeueReusableCell(withIdentifier: "dashboardCell", for: index) as! DashboardCell
        defaultCell.setup(with: cellType)
        return defaultCell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard serial.isReady else {
            presentSimpleAlert(with: "Not connected", message: "Connect to the vehicle first.", buttonTitle: "Dismiss")
            return
        }
        
        guard let cell = tableView.cellForRow(at: indexPath) as? DashboardCell else { return }
        cell.cellAction { [weak self] in
            self?.tableView.reloadData()
        }
        tableView.reloadData()
    }
}

//MARK: - BluetoothSerialDelegate

extension HomeVC: BluetoothSerialDelegate  {
    
    func serialDidDiscoverPeripheral(_ peripheral: CBPeripheral, RSSI: NSNumber?) {
        
        // check whether it is a duplicate
        for exisiting in peripherals {
            if exisiting.peripheral.identifier == peripheral.identifier { return }
        }
        
        // add to the array, next sort & reload
        let theRSSI = RSSI?.floatValue ?? 0.0
        peripherals.append((peripheral: peripheral, RSSI: theRSSI))
        peripherals.sort { $0.RSSI < $1.RSSI }
        
        if peripheral.identifier.uuidString == remoteStarterId {
            selectedPeripheral = peripheral
            connect()
        }
    }
    
    func serialDidFailToConnect(_ peripheral: CBPeripheral, error: NSError?) {
        isConnecting = false
        dismissLoader()
        
        title = "Failed to connect"
        showLoader(withText: "Failed to connect", dismissAfter: 2)
        if let _ = selectedPeripheral {
            connect()
        } else {
            serial.startScan()
        }
    }
    
    func serialDidConnect(_ peripheral: CBPeripheral) {
        isConnected = true
        title = "Connected"
    }
    
    func serialIsReady(_ peripheral: CBPeripheral) {
        dismissLoader()
        Helper.delay(1.5) {
            self.commandsManager.unlock()
            self.commandsManager.isLocked = false
        }
        readRssiTimer()
        lockOverride = false
    }
    
    @objc private func serialDidReceiveString(_ notification: NSNotification) {
            // add the received text to the textView, optionally with a line break at the end
            
            guard let dict = notification.userInfo as NSDictionary? else { return }
            guard let message = dict["comand"] as? String else { return }
            
            let msgArr = message.components(separatedBy: "\r\n")
            for separatedMsg in msgArr {
                let msg = separatedMsg.replacingOccurrences(of: "\r\n", with: "")
                if msg == "" { break }
                print(msg)
                switch msg {
                case "ignOn":
                    commandsManager.isIgnitionOn = true
                case "ignOff":
                    commandsManager.isIgnitionOn = false
                case "starterOn":
                    break
                case "starterOff":
                    break
                case "unlockOn":
                    break
                case "unlockOff":
                    break
                case "lightsOn":
                    commandsManager.isLightsOn = true
                case "lightsOff":
                    commandsManager.isLightsOn = false
                default:
                    break
                }
            }
            tableView.reloadData()
        }
    
    func serialDidDisconnect(_ peripheral: CBPeripheral, error: NSError?) {
        
        showLoader(withText: "Disconnected", dismissAfter: 1)
        title = "Disconnected"
        if let _ = selectedPeripheral {
            connect()
        } else {
            serial.startScan()
        }
    }
    
    func serialDidChangeState() {
        
        if serial.centralManager.state != .poweredOn {
            showLoader(withText: "Bluetooth turned off", dismissAfter: 1)
        }
    }
}
