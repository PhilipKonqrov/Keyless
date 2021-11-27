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
    var isStarted = false
    var isIgnitionOn = false
    var isLightsOn = false
    var isLocked = true
    var lockOverride = false
//    let remoteStarterId = "637D5AC5-3EED-DAE7-8E10-FA550CA6877E"
    let remoteStarterId = "39B01AB6-EABC-3B29-5B46-7D92A28DFF9C"
    var refreshControl = UIRefreshControl()
    var selectedPeripheral: CBPeripheral?
    var loader: UIAlertController?
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.serialDidReceiveString(_:)), name: NSNotification.Name(rawValue: "bleCommandReceived"), object: nil)
        
        delay(1) {
            self.scanBT()
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        delay(3) { [weak self] in
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
            
            self.delay(5) {
                self.dismiss(animated: true)
            }
        }
    }
    
    @objc func refresh(_ sender: AnyObject) {
        refreshControl.endRefreshing()
        isConnecting = false
        scanBT()
    }
    
    private func delay(_ delay:Double, closure:@escaping ()->()) {
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
        
        dismissLoader()
        showLoader(withText: "Failed to connect", dismissAfter: 2)
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
    
    func unlock() {
        if !serial.isReady {
            notConnectedAlert()
            return
        }
        serial.sendMessageToDevice("unlock")
        delay(2.3) {
            // fix for e34 double unlock problem, not needed for other cars
            serial.sendMessageToDevice("unlock")
        }
        isLocked = false
        
    }
    func lock() {
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
            guard isIgnitionOn else {
                serial.sendMessageToDevice("ignOn")
                isIgnitionOn = true
                delay(1.5) {
                    serial.sendMessageToDevice("lightsOn")
                    self.isLightsOn = true
                    self.tableView.reloadData()
                }
                return
            }
            
            serial.sendMessageToDevice("lightsOn")
            self.isLightsOn = true
            self.tableView.reloadData()
            
        } else {
            serial.sendMessageToDevice("lightsOff")
            self.isLightsOn = false
            self.tableView.reloadData()
        }
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
        delay(10) {
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
            let cell = tableView.dequeueReusableCell(withIdentifier: "dashboardCell", for: indexPath) as! DashboardCell
            cell.selectionStyle = .none
            if !isIgnitionOn {
                cell.label.text = "Ignition on"
                cell.container.backgroundColor = UIColor(named: "customBlue")
            } else {
                cell.label.text = "Ignition off"
                cell.container.backgroundColor = #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
            }
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "dashboardCell", for: indexPath) as! DashboardCell
            cell.selectionStyle = .none
            if !isStarted {
                cell.label.text = "Start engine"
            } else {
                cell.label.text = "Stop engine"
            }
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "LockUnlockCell", for: indexPath) as! LockUnlockCell
            cell.selectionStyle = .none
            cell.dashboardReference = self
            return cell
        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: "dashboardCell", for: indexPath) as! DashboardCell
            cell.selectionStyle = .none
            if !isLightsOn {
                cell.label.text = "Lights on"
                cell.container.backgroundColor = UIColor(named: "customBlue")
            } else {
                cell.label.text = "Lights off"
                cell.container.backgroundColor = #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
            }
            return cell
        default:
            break
        }
        return UITableViewCell()
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
        case 3:
            headlights()
        default:
            break
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
        if peripheral.identifier.uuidString == remoteStarterId {
            isConnected = true
            title = "Connected"
        }
    }
    
    func serialIsReady(_ peripheral: CBPeripheral) {
        dismissLoader()
        delay(1.5) {
            self.unlock()
            self.isLocked = false
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
                    isIgnitionOn = true
                case "ignOff":
                    isIgnitionOn = false
                case "starterOn":
                    break
                case "starterOff":
                    break
                case "unlockOn":
                    break
                case "unlockOff":
                    break
                case "lightsOn":
                    isLightsOn = true
                case "lightsOff":
                    isLightsOn = false
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
