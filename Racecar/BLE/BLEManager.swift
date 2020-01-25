//
//  BLEManager.swift
//  Racecar
//
//  Created by Taylor McIntyre on 2020-01-25.
//  Copyright © 2020 Taylor McIntyre. All rights reserved.
//

import Foundation
import CoreBluetooth

/*
class BLEManager: NSObject, ObservableObject {
    lazy var manager: CBCentralManager = {
        let m = CBCentralManager(delegate: self, queue: nil)
        return m
    }()
    
    @Published var servo1Angle: Double = 0
    @Published var servo2Angle: Double = 0
    @Published var type: Int = 0
    
    @Published var automatic = false {
        didSet {
            if automatic {
                performSequence()
            }
        }
    }
        
    @Published var peripherals: [CBPeripheral] = []
    @Published var isScanning = false
    @Published var connectedPeripheral: CBPeripheral? {
        didSet {
            connectedPeripheral?.delegate = self
            discoverServices()
        }
    }
    
    let autoConnect: Bool
    
    private var motorCancellable: Cancellable? {
        didSet {
            oldValue?.cancel()
        }
    }
    
    var txCharacteristic: CBCharacteristic?
    var rxCharacteristic: CBCharacteristic?
    
    override init() {
        self.autoConnect = CommandLine.arguments.contains("--autoconnect")
        super.init()
        
        let debounce = 500
        
        let servo1 = $servo1Angle
            .debounce(for: .microseconds(debounce), scheduler: DispatchQueue.main)
            .removeDuplicates()
        
        let servo2 = $servo2Angle
            .debounce(for: .microseconds(debounce), scheduler: DispatchQueue.main)
            .removeDuplicates()
        
        motorCancellable = Publishers
            .CombineLatest(servo1, servo2)
            .map { (Int($0), Int($1)) }
            .sink(receiveValue: { servo1, servo2 in
                self.writeValue(message: "\(self.type),\(servo1),\(servo2)")
            })
        
        if autoConnect {
            startScanning()
        }
    }
    
    func setBySlider(for slider: Int, value: Double) {
        type = 0
        switch slider {
        case 1: servo1Angle = value
        case 2: servo2Angle = value
        default: fatalError("not a knnown slider")
        }
    }
    
    func setByButton(for slider: Int, value: Double) {
        type = 1
        switch slider {
        case 1: servo1Angle = value
        case 2: servo2Angle = value
        default: fatalError("not a knnown slider")
        }
    }
    
    var canSend: Bool {
        return txCharacteristic != nil
    }
    
    func startScanning() {
        print("Started scanning...")
        isScanning = true
        manager.scanForPeripherals(withServices: [BLEService_UUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            self?.stopScanning()
        }
    }
    
    func stopScanning() {
        print("Stopped scanning...")
        isScanning = false
        manager.stopScan()
        peripherals = []
    }
    
    func connect(to peripheral: CBPeripheral) {
        manager.connect(peripheral, options: nil)
    }
    
    func disconnect(peripheral: CBPeripheral) {
        if let connected = connectedPeripheral {
            manager.cancelPeripheralConnection(connected)
        }
        connectedPeripheral = nil
        txCharacteristic = nil
        rxCharacteristic = nil
    }
    
    func writeValue(message: String) {
        print(message)
        let data = Data(message.utf8)
        if let connected = connectedPeripheral, let tx = txCharacteristic {
            connected.writeValue(data, for: tx, type: .withResponse)
        }
    }
    
    func discoverServices() {
        connectedPeripheral?.discoverServices([BLEService_UUID])
    }
    
    func discoverCharacteristics(for service: CBService) {
        connectedPeripheral?.discoverCharacteristics(nil, for: service)
    }
    
    func reset() {
        self.writeValue(message: "1,100,0")
    }
    
    func performSequence() {
        DispatchQueue.global().async {
            while self.automatic {
                let delay: UInt32 = 2
                self.writeValue(message: "1,0,0")
                sleep(delay)
                self.writeValue(message: "1,100,0")
                sleep(delay)
                self.writeValue(message: "1,100,90")
                sleep(delay)
                self.writeValue(message: "1,0,90")
                sleep(delay)
                self.writeValue(message: "1,100,90")
                sleep(delay)
                self.writeValue(message: "1,100,0")
                sleep(delay)
            }
        }
    }
}

extension BLEManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("Manager did update state: \(central.state.rawValue) \(central.state)")
        guard central.state == .poweredOn else {
            return
        }
        
        startScanning()
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("didDiscover: \(peripheral.name ?? "no name")")
        self.peripherals.append(peripheral)
        
        if autoConnect {
            self.connect(to: peripheral)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("didConnect: \(peripheral.name ?? "no name")")
        stopScanning()
        
        connectedPeripheral = peripheral
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("didFailToConnect: \(peripheral.name ?? ""), error: \(error?.localizedDescription ?? "none")")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if peripheral == connectedPeripheral {
            connectedPeripheral = nil
        }
        print("didDisconnectPeripheral: \(peripheral.name ?? ""), error: \(error?.localizedDescription ?? "none")")
    }
}

extension BLEManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("didDiscoverServices: error \(error)")
            return
        }
        
        guard let services = peripheral.services else {
            print("no services")
            return
        }
        
        print("didDiscoverServices: \(services.count)")
        services.forEach { discoverCharacteristics(for: $0) }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        print("didDiscoverDescriptorsFor: \(characteristic)")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("didDiscoverCharacteristicsFor: error \(error)")
            return
        }
        
        guard let characteristics = service.characteristics else {
            print("no characteristics")
            return
        }
        
        for characteristic in characteristics {
            if characteristic.uuid.isEqual(BLE_Characteristic_uuid_Rx)  {
                rxCharacteristic = characteristic
                
                connectedPeripheral?.setNotifyValue(true, for: characteristic)
                connectedPeripheral?.readValue(for: characteristic)
                print("Rx Characteristic: \(characteristic.uuid)")
            }
            
            if characteristic.uuid.isEqual(BLE_Characteristic_uuid_Tx) {
                txCharacteristic = characteristic
                
                print("Tx Characteristic: \(characteristic.uuid)")
            }
            
            connectedPeripheral?.discoverDescriptors(for: characteristic)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic == rxCharacteristic {
            if let value = characteristic.value {
                let string = String(decoding: value, as: UTF8.self)
                print("Value Recieved: \(string)")
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("didWriteValueFor: error \(error)")
            return
        }
    }
}
*/
