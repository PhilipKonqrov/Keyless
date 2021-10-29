//
//  NewController.swift
//  Serial
//
//  Created by Philip Plamenov on 23.06.20.
//  Copyright © 2020 Balancing Rock. All rights reserved.
//

import UIKit
import CoreBluetooth
class NewController: UIViewController, BluetoothSerialDelegate, Loadable {
    
    @IBOutlet weak var tableView: UITableView!
    var loader: UIView?
    var isConnecting = false
    var isConnected = false
    var isStarted = false
    var isIgnitionOn = false
    var isLightsOn = false
    var isLocked = true
    var lockOverride = false
    var progressHUD: MBProgressHUD?
//    let remoteStarterId = "637D5AC5-3EED-DAE7-8E10-FA550CA6877E"
    let remoteStarterId = "39B01AB6-EABC-3B29-5B46-7D92A28DFF9C"
    var refreshControl = UIRefreshControl()
    var selectedPeripheral: CBPeripheral?
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
        tableView.addSubview(refreshControl)
        // init serial
        serial = BluetoothSerial(delegate: self)
        serial.delegate = self
        
        delay(1) {
            self.scanBT()
        }
        
    }
    
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        presentLoader()
//    }
    
    @objc func refresh(_ sender: AnyObject) {
        refreshControl.endRefreshing()
        isConnecting = false
        scanBT()
    }
    
    func delay(_ delay:Double, closure:@escaping ()->()) {
        let when = DispatchTime.now() + delay
        DispatchQueue.main.asyncAfter(deadline: when, execute: closure)
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
        
        if let hud = progressHUD {
            hud.hide(false)
        }
        
        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        hud?.mode = MBProgressHUDMode.text
        hud?.labelText = "Failed to connect"
        hud?.hide(true, afterDelay: 2)
    }
    
    func notConnectedAlert() {
        let alert = UIAlertController(title: "Not connected", message: "Connect to the vehicle first.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertAction.Style.default, handler: { action -> Void in self.dismiss(animated: true, completion: nil) }))
        present(alert, animated: true, completion: nil)
    }
    
    private func startEngine() {
        if !serial.isReady {
            notConnectedAlert()
            return
        }
        startIgnition()
        delay(1) { [weak self] in
            guard let self = self else { return }
            if !self.isStarted {
                serial.sendMessageToDevice("startEngine")
                self.isStarted = true
                self.isIgnitionOn = true
            } else {
                serial.sendMessageToDevice("stopEngine")
                self.isStarted = false
                self.isIgnitionOn = false
            }
        }
        
        
    }
    
    private func startIgnition() {
        if !serial.isReady {
            notConnectedAlert()
            return
        }
        if !isIgnitionOn {
            serial.sendMessageToDevice("ignOn")
            isIgnitionOn = true
        } else {
            serial.sendMessageToDevice("ignOff")
            isIgnitionOn = false
            isStarted = false
        }
    }
    
    private func unlock() {
        if !serial.isReady {
            notConnectedAlert()
            return
        }
        serial.sendMessageToDevice("unlock")
        delay(2.3) {
            // fix for e34 dooble unlock problem, not needed for other cars
            serial.sendMessageToDevice("unlock")
        }
        isLocked = false
        
    }
    private func lock() {
        if !serial.isReady {
            notConnectedAlert()
            return
        }
        serial.sendMessageToDevice("lock")
        isLocked = true
    }
    
    private func headlights() {
        if !serial.isReady {
            notConnectedAlert()
            return
        }
        if !isLightsOn {
            serial.sendMessageToDevice("ignOn")
            isIgnitionOn = true
            delay(1.5) {
                serial.sendMessageToDevice("lightsOn")
                self.isLightsOn = true
                self.tableView.reloadData()
            }
        } else {
            serial.sendMessageToDevice("ignOff")
            isIgnitionOn = false
            delay(1.5) {
                serial.sendMessageToDevice("lightsOff")
                self.isLightsOn = false
                self.tableView.reloadData()
            }
        }
    }
    
    @IBAction func connect(_ sender: Any) {
        performSegue(withIdentifier: "scanBT", sender: self)
    }
    
    //MARK: BluetoothSerialDelegate
    
    func serialDidDiscoverPeripheral(_ peripheral: CBPeripheral, RSSI: NSNumber?) {
        if peripheral.identifier.uuidString == remoteStarterId {
            selectedPeripheral = peripheral
            connect()
        }
    }
    
    func serialDidReadRSSI(_ rssi: NSNumber) {
        print("Signal rssi: \(rssi)")
//        print(rssi.intValue)
        if rssi.intValue < -90 && !lockOverride {
            if isLocked { return }
            lock()
        } else if rssi.intValue > -85 && !lockOverride {
            if !isLocked { return }
            unlock()
        }
    }
    
    func connect() {
        if isConnecting { return }
        isConnecting = true
        guard let peripheral = selectedPeripheral else { return }
        serial.stopScan()
        serial.connectToPeripheral(peripheral)
        progressHUD = MBProgressHUD.showAdded(to: view, animated: true)
        progressHUD!.labelText = "Connecting"
        
        delay(10) {
            self.connectTimeOut()
        }
    }
    
    func serialDidFailToConnect(_ peripheral: CBPeripheral, error: NSError?) {
        isConnecting = false
        if let hud = progressHUD {
            hud.hide(false)
        }
        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        hud?.mode = MBProgressHUDMode.text
        title = "Failed to connect"
        hud?.labelText = "Failed to connect"
        hud?.hide(true, afterDelay: 1.0)
        if let _ = selectedPeripheral {
            connect()
        } else {
            serial.startScan()
        }
    }
    
    func serialDidConnect(_ peripheral: CBPeripheral) {
        if peripheral.identifier.uuidString == remoteStarterId {
            isConnected = true
            title = "Connected"
        }
    }
    
    func serialIsReady(_ peripheral: CBPeripheral) {
        if let hud = progressHUD {
            hud.hide(false)
            delay(1.5) {
                self.unlock()
                self.isLocked = false
            }
            readRssiTimer()
            lockOverride = false
        }
    }
    
    private func readRssiTimer() {
         Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { (Timer) in
             serial?.readRSSI()
         })
     }
    
    func serialDidReceiveString(_ message: String) {
        // add the received text to the textView, optionally with a line break at the end
        
    }
    
    func serialDidDisconnect(_ peripheral: CBPeripheral, error: NSError?) {
//        isConnecting = false
        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        hud?.mode = MBProgressHUDMode.text
        title = "Disconnected"
        hud?.labelText = "Disconnected"
        hud?.hide(true, afterDelay: 1.0)
        if let _ = selectedPeripheral {
            connect()
        } else {
            serial.startScan()
        }
    }
    
    func serialDidChangeState() {
        
        if serial.centralManager.state != .poweredOn {
            let hud = MBProgressHUD.showAdded(to: view, animated: true)
            hud?.mode = MBProgressHUDMode.text
            hud?.labelText = "Bluetooth turned off"
            hud?.hide(true, afterDelay: 1.0)
        }
    }
    
}
extension NewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "dashboardCell", for: indexPath) as! DashboardCell
        cell.selectionStyle = .none
        
        switch indexPath.row {
        case 0:
            if !isIgnitionOn {
                cell.label.text = "Ignition on"
            } else {
                cell.label.text = "Ignition off"
            }
        case 1:
            if !isStarted {
                cell.label.text = "Start engine"
            } else {
                cell.label.text = "Stop engine"
            }
        case 2:
            cell.label.text = "Unlock"
        case 3:
            cell.label.text = "Lock"
        case 4:
            if !isLightsOn {
                cell.label.text = "Lights on"
            } else {
                cell.label.text = "Lights off"
            }
        default:
            break
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.row {
        case 0:
            startIgnition()
        case 1:
            startEngine()
        case 2:
            lockOverride = true
            unlock()
        case 3:
            lockOverride = true
            lock()
        case 4:
            headlights()
        default:
            break
        }
        tableView.reloadData()
    }
}
