//
//  BLEManager.swift
//  Racecar
//
//  Created by Taylor McIntyre on 2020-01-25.
//  Copyright © 2020 Taylor McIntyre. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol BluetoothManagerDelegate: AnyObject {
    func didConnect(to peripheral: CBPeripheral)
    func didDisconnect(from peripheral: CBPeripheral)
    func didDiscover()
}

class BluetoothManager: NSObject {
    lazy var manager: CBCentralManager = {
        let m = CBCentralManager(delegate: self, queue: nil)
        return m
    }()
        
    weak var delegate: BluetoothManagerDelegate?
    
    var isScanning = false
    var peripherals: [CBPeripheral] = [] {
        didSet {
            delegate?.didDiscover()
        }
    }
    
    let autoConnect: Bool
    
    override init() {
        self.autoConnect = CommandLine.arguments.contains("--autoconnect")
        super.init()
        
        if autoConnect {
            startScanning()
        }
    }
    
    // MARK: Scanning
    func startScanning() {
        isScanning = true
        
        let options = [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        manager.scanForPeripherals(withServices: [BLEService_UUID], options: options)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            self?.stopScanning()
        }
    }
    
    func stopScanning() {
        isScanning = false
        manager.stopScan()
        peripherals.removeAll()
    }
    
    // MARK: Connections
    func connect(to peripheral: CBPeripheral) {
        manager.connect(peripheral, options: nil)
    }
    
    // MARK: Disconnections
    func disconnect(from peripheral: CBPeripheral) {
        manager.cancelPeripheralConnection(peripheral)
    }
}

extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard central.state == .poweredOn else {
            return
        }
        
        startScanning()
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        self.peripherals.append(peripheral)
        
        if autoConnect {
            connect(to: peripheral)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        stopScanning()
        delegate?.didConnect(to: peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("didFailToConnect: \(peripheral.name ?? ""), error: \(error?.localizedDescription ?? "none")")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        delegate?.didDisconnect(from: peripheral)
    }
}
