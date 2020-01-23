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

//
// Entity public names
//
internal let kEntityRedLed          = "redled"
internal let kEntityGreenLed        = "greenled"

//
// Publication topics
//
public extension Notification.Name {
    static let entityRedLed = Notification.Name(kEntityRedLed)
    static let entityGreenLed = Notification.Name(kEntityGreenLed)
}

//
// Publication Payloads
internal struct BinaryPayload {
    var value: Bool
    var isNotifying: Bool
    var didWrite: Bool
}

//
// Entity permissions
fileprivate let kPermitRead         = UInt8(0x01)
fileprivate let kPermitWrite        = UInt8(0x02)
fileprivate let kPermitNotify       = UInt8(0x04)

//
// UUID strings
fileprivate let tiBaseUuid              = "F0000000-0451-4000-B000-000000000000"
// LED Service
fileprivate let ledServiceShortUuid     = "1110"
fileprivate let redLedShortUuid         = "1111"
fileprivate let greenLedShortUuid       = "1112"

//
// CBUUIDs
// LED Service
fileprivate let ledServiceUuid = CBUUID(baseUuid: tiBaseUuid, shortUuid: ledServiceShortUuid)
fileprivate let redLedUuid = CBUUID(baseUuid: tiBaseUuid, shortUuid: redLedShortUuid)
fileprivate let greenLedUuid = CBUUID(baseUuid: tiBaseUuid, shortUuid: greenLedShortUuid)

fileprivate let defaultService = ledServiceUuid

//
// Entity definitions
//
fileprivate protocol Entity {
    associatedtype T
    associatedtype U
    
    var name: String { get }
    var topic: Notification.Name { get }
    var bleService: BleService { get }
    var isNotifying: Bool { get set }
    var didWrite: Bool { get set }
    var suuid: CBUUID { get }
    var cuuid: CBUUID { get }
    var permission: UInt8 { get }
    var value: T { get set }
    var bleValue: U { get set }
    
    // Client inbound
    func get()
    func set(value: T, response: Bool)
    func setNotify(state: Bool)
    // Ble inbound
    func valueChanged(data: Data)
    mutating func writeConfirm()
    mutating func notifyStateChanged(state: Bool)
    // Publication
    func publish()
}

fileprivate extension Entity {
    // Client inbound default implementations
    func get() {
        //
    }
    
    func setNotify(state: Bool) {
        //
    }
    
    // Ble inbound default implementations
    mutating func writeConfirm() {
        //
    }
    
    mutating func notifyStateChanged(state: Bool) {
        //
    }
    
}

fileprivate class BinaryEntity: Entity {
    typealias T = Bool
    typealias U = UInt8
    
    let name: String
    let topic: Notification.Name
    let bleService: BleService
    var isNotifying: Bool = false
    var didWrite: Bool = false
    let suuid: CBUUID
    let cuuid: CBUUID
    let permission: UInt8
    var value: T
    var bleValue: U
    
    init(name: String, topic: Notification.Name, suuid: CBUUID, cuuid: CBUUID, permission: UInt8, bleService: BleService, defaultValue: T) {
        self.name = name
        self.topic = topic
        self.bleService = bleService
        self.suuid = suuid
        self.cuuid = cuuid
        self.permission = permission
        self.value = defaultValue
        self.bleValue = defaultValue == false ? 0 : 1
    }
    
    // Client inbound
    func set(value: T, response: Bool) {
        //
    }
    
    // Ble inbound
    func valueChanged(data: Data) {
        //
    }
    
    // Publication
    func publish() {
        //
    }
    
}

//
// Entity Types
fileprivate enum EntityType {
    case binary(BinaryEntity)
}

// MARK: - Model class
//
internal final class Model {
    
    private let bleService: BleService
    private let primaryService: CBUUID
    private var bleStatus: BleStatus = .offLine
    private let redLed: BinaryEntity
    private let greenLed: BinaryEntity
    private let lookUpByEntity: [String : EntityType]
    private let lookUpByCharac: [CBUUID : EntityType]

    init(bleService: BleService, primaryService: CBUUID = defaultService) {
        self.bleService = bleService
        self.primaryService = primaryService
        redLed = BinaryEntity(name: kEntityRedLed,
                              topic: .entityRedLed,
                              suuid: ledServiceUuid,
                              cuuid: redLedUuid,
                              permission: kPermitRead | kPermitWrite,
                              bleService: bleService,
                              defaultValue: false)
        greenLed = BinaryEntity(name: kEntityGreenLed,
                                topic: .entityGreenLed,
                                suuid: ledServiceUuid,
                                cuuid: greenLedUuid,
                                permission: kPermitRead | kPermitWrite,
                                bleService: bleService,
                                defaultValue: false)
        lookUpByEntity = [kEntityRedLed : .binary(redLed),
                          kEntityGreenLed : .binary(greenLed)
        ]
        lookUpByCharac = [redLedUuid : .binary(redLed),
                          greenLedUuid : .binary(greenLed)
        ]
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
                        self.bleService.attachPeripheral(suuid: self.primaryService, forceScan: false)
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
