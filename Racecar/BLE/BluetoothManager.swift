//
//  BLEManager.swift
//  Racecar
//
//  Created by Taylor McIntyre on 2020-01-25.
//  Copyright © 2020 Taylor McIntyre. All rights reserved.
//

import Foundation
import CoreBluetooth

// https://github.com/bradhowes/Joystick
// https://github.com/MitrofD/TLAnalogJoystick

class BluetoothManager: NSObject {
    lazy var manager: CBCentralManager = {
        let m = CBCentralManager(delegate: self, queue: nil)
        return m
    }()
    
    var peripheralManager: PeripheralManager?
        
    var peripherals: [CBPeripheral] = []
    var isScanning = false
    
    let autoConnect: Bool
    
    override init() {
        self.autoConnect = CommandLine.arguments.contains("--autoconnect")
        super.init()
        
        let _ = 500
        
        if autoConnect {
            startScanning()
        }
    }
    
    // MARK: Scanning
    func startScanning() {
        isScanning = true
        
        manager.scanForPeripherals(
            withServices: [BLEService_UUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
        
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
    
    func didConnectTo(peripheral: CBPeripheral) {
        let manager = PeripheralManager(peripheral)
        manager.delegate = self
        
        peripheralManager = manager
    }
    
    // MARK: Disconnections
    func disconnect() {
        guard let peripheral = peripheralManager?.peripheral else { return }
        manager.cancelPeripheralConnection(peripheral)
    }
    
    func didDisconnect(peripheral: CBPeripheral) {
        guard peripheral.identifier == peripheralManager?.peripheral.identifier else { return }
        peripheralManager = nil
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
            stopScanning()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        stopScanning()
        didConnectTo(peripheral: peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("didFailToConnect: \(peripheral.name ?? ""), error: \(error?.localizedDescription ?? "none")")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        didDisconnect(peripheral: peripheral)
    }
}

extension BluetoothManager: PeripheralManagerDelegate {
    
}
