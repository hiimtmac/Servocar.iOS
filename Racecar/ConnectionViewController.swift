//
//  ConnectionViewController.swift
//  Racecar
//
//  Created by Taylor McIntyre on 2020-02-02.
//  Copyright © 2020 Taylor McIntyre. All rights reserved.
//

import UIKit
import CoreBluetooth

class ConnectionViewController: UIViewController {
    lazy var bluetooth: BluetoothManager = {
        let b = BluetoothManager()
        b.delegate = self
        return b
    }()
    
    lazy var tableView: UITableView = {
        let t = UITableView()
        t.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        t.rowHeight = 44
        t.dataSource = self
        t.delegate = self
        return t
    }()
    
    lazy var startButton: UIButton = {
        let b = UIButton.bleButton
        b.addTarget(self, action: #selector(handleStart(_:)), for: .touchUpInside)
        b.setTitle("Start Scanning", for: .normal)
        return b
    }()
    
    lazy var stopButton: UIButton = {
        let b = UIButton.bleButton
        b.addTarget(self, action: #selector(handleStop(_:)), for: .touchUpInside)
        b.setTitle("Stop Scanning", for: .normal)
        return b
    }()
    
    var connected: CBPeripheral?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Connections"
        
        let stack = UIStackView(arrangedSubviews: [startButton, stopButton])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.distribution = .fillEqually
        stack.spacing = 5
        
        view.addSubview(stack)
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            
        ])
    }
    
    @objc func handleStart(_ selector: UIButton) {
        bluetooth.startScanning()
    }
    
    @objc func handleStop(_ selector: UIButton) {
        bluetooth.stopScanning()
    }
}

extension ConnectionViewController: BluetoothManagerDelegate {
    func didConnect(to peripheral: CBPeripheral) {
        connected = peripheral
        if let id = bluetooth.peripherals.firstIndex(of: peripheral) {
            let idp = IndexPath(row: id, section: 0)
            if let cell = tableView.cellForRow(at: idp) {
                cell.accessoryType = .checkmark
            }
        }
    }
    
    func didDisconnect(from peripheral: CBPeripheral) {
        connected = nil
        if let id = bluetooth.peripherals.firstIndex(of: peripheral) {
            let idp = IndexPath(row: id, section: 0)
            if let cell = tableView.cellForRow(at: idp) {
                cell.accessoryType = .none
            }
        }
    }
    
    func didDiscover() {
        tableView.reloadData()
    }
}

extension ConnectionViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bluetooth.peripherals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let peripheral = bluetooth.peripherals[indexPath.row]
        cell.textLabel?.text = peripheral.name
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let peripheral = bluetooth.peripherals[indexPath.row]
        if peripheral == connected {
            bluetooth.disconnect(from: peripheral)
        } else {
            bluetooth.connect(to: peripheral)
        }
    }
}

private extension UIButton {
    static var bleButton: UIButton {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.layer.cornerRadius = 5
        return b
    }
}
