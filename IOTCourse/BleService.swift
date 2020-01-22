//
//  BleService.swift
//  IOTCourse
//
//  Created by Andrew Coad on 22/01/2020.
//  Copyright © 2020 Andrew Coad. All rights reserved.
//

import Foundation
import CoreBluetooth
import os


// MARK: - BleService class
//
internal final class BleService: NSObject {
    
    private var centralManager: CBCentralManager?
    private let initOptions = [CBCentralManagerOptionShowPowerAlertKey : NSNumber(value: true)]

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self,
                                          queue: DispatchQueue(label: "com.iotcourse.bleq",
                                                               qos: .userInitiated),
                                          options: initOptions)
    }
    
    // MARK: - Public (Internal) API
    //
    func attachPeripheral(suuid: CBUUID) {
        //
    }
    
    func read(suuid: CBUUID, cuuid: CBUUID) {
        //
    }
    
    func write(suuid: CBUUID, cuuid: CBUUID, data: Data, response: Bool) {
        //
    }
    
    func setNotify(suuid: CBUUID, cuuid: CBUUID, state: Bool) {
        //
    }
    
    func readRssi() {
        //
    }

}

// MARK: - CBCentralManagerDelegate
//
extension BleService: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        os_log("Central Manager state: %s", log: Log.ble, type: .info, central.state.description)
    }
}

// MARK: - CBPeripheralDelegate
//
extension BleService: CBPeripheralDelegate {
    //
}
