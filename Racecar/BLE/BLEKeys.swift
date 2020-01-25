//
//  BLEKeys.swift
//  Racecar
//
//  Created by Taylor McIntyre on 2020-01-25.
//  Copyright © 2020 Taylor McIntyre. All rights reserved.
//

import CoreBluetooth

private let kBLEService_UUID = "6e400001-b5a3-f393-e0a9-e50e24dcca9e"
private let kBLE_Characteristic_uuid_Tx = "6e400002-b5a3-f393-e0a9-e50e24dcca9e"
private let kBLE_Characteristic_uuid_Rx = "6e400003-b5a3-f393-e0a9-e50e24dcca9e"
let MaxCharacters = 20

let BLEService_UUID = CBUUID(string: kBLEService_UUID)
let BLE_Characteristic_uuid_Tx = CBUUID(string: kBLE_Characteristic_uuid_Tx)
let BLE_Characteristic_uuid_Rx = CBUUID(string: kBLE_Characteristic_uuid_Rx)
