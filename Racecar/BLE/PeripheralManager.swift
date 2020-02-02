//
//  PeripheralManager.swift
//  Racecar
//
//  Created by Taylor McIntyre on 2020-02-01.
//  Copyright © 2020 Taylor McIntyre. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol PeripheralManagerDelegate: AnyObject {
    
}

class PeripheralManager: NSObject {
    let peripheral: CBPeripheral
    weak var delegate: PeripheralManagerDelegate?
    
    var txCharacteristic: CBCharacteristic?
    var rxCharacteristic: CBCharacteristic?
    
    init(_ peripheral: CBPeripheral) {
        self.peripheral = peripheral
        super.init()
        
        discoverServices()
    }
    
    func discoverServices() {
        peripheral.discoverServices([BLEService_UUID])
    }
    
    func writeMessage(_ value: String) {
        let data = Data(value.utf8)
        if let tx = txCharacteristic {
            peripheral.writeValue(data, for: tx, type: .withResponse)
        }
    }
}

extension PeripheralManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("didDiscoverServices: error \(error)")
            return
        }
        
        peripheral.services?.forEach { peripheral.discoverCharacteristics(nil, for: $0) }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("didDiscoverCharacteristicsFor: error \(error)")
            return
        }
        
        service.characteristics?.forEach { characteristic in
            if characteristic.uuid.isEqual(BLE_Characteristic_uuid_Rx)  {
                rxCharacteristic = characteristic
                
                peripheral.setNotifyValue(true, for: characteristic)
                peripheral.readValue(for: characteristic)
            }
            
            if characteristic.uuid.isEqual(BLE_Characteristic_uuid_Tx) {
                txCharacteristic = characteristic                
            }
            
            peripheral.discoverDescriptors(for: characteristic)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        //
    }
    
    // Incoming from device
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
//        if characteristic == rxCharacteristic {
//            if let value = characteristic.value {
//                self.delegate?.peripheral(didSend: value)
//            }
//        }
    }
    
    // Outgoing to device
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
//        if let error = error {
//            delegate?.peripheral(didWriteError: error)
//            return
//        }
    }
}
