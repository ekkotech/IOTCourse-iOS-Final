//
//  Model.swift
//  IOTCourse
//
//  Created by Andrew Coad on 22/01/2020.
//  Copyright © 2020 Andrew Coad. All rights reserved.
//

import Foundation
import CoreBluetooth
import os

fileprivate let defaultService = CBUUID(string: "F0001110-0451-4000-B000-000000000000")

// MARK: - Model class
//
internal final class Model {
    
    private let bleService: BleService
    private let primaryService: CBUUID
    private var bleStatus: BleStatus = .offLine

    init(bleService: BleService, primaryService: CBUUID = defaultService) {
        self.bleService = bleService
        self.primaryService = primaryService
        setupSubscriptions()
    }

    // MARK: - Private functions
    //
    private func setupSubscriptions() {
        // Status
        nc.addObserver(forName: .bleStatus, object: nil, queue: nil, using: { notification in
            
            if let payload = notification.object as? BleStatusPayload {
                self.bleStatus = payload.status
                os_log("BleService is %s", log: Log.model, type: .info, payload.status.description)
                switch payload.status {
                    case .onLine:
                        self.bleService.attachPeripheral(suuid: self.primaryService)
                    case .offLine:
                        break
                    case .ready:
                        break
                }
            }})
        
    }

    // MARK: - Public (Internal) API
    //
    func get(entity: String) {
        //
    }
    
    func set(entity: String, value: Bool, response: Bool) {
        //
    }
    
    func setNotify(entity: String, state: Bool) {
        //
    }
    
    func getRssi() {
        //
    }

}
