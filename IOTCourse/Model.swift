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
internal let kEntityLeftButton      = "leftbutton"
internal let kEntityRightButton     = "rightbutton"
internal let kEntityRSSI            = "rssi"        // NOTE: Not a real entity

//
// Publication topics
//
public extension Notification.Name {
    static let entityRedLed = Notification.Name(kEntityRedLed)
    static let entityGreenLed = Notification.Name(kEntityGreenLed)
    static let entityLeftButton = Notification.Name(kEntityLeftButton)
    static let entityRightButton = Notification.Name(kEntityRightButton)
    static let entityRSSI = Notification.Name(kEntityRSSI)
}

//
// Publication Payloads
internal struct BinaryPayload {
    var value: Bool
    var isNotifying: Bool
    var didWrite: Bool
}

internal struct IntegerPayload {
    var value: Int
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
// Button service
fileprivate let buttonServiceShortUuid  = "1120"
fileprivate let leftButtonShortUuid     = "1121"
fileprivate let rightButtonShortUuid    = "1122"

//
// CBUUIDs
// LED Service
fileprivate let ledServiceUuid = CBUUID(baseUuid: tiBaseUuid, shortUuid: ledServiceShortUuid)
fileprivate let redLedUuid = CBUUID(baseUuid: tiBaseUuid, shortUuid: redLedShortUuid)
fileprivate let greenLedUuid = CBUUID(baseUuid: tiBaseUuid, shortUuid: greenLedShortUuid)
// Button service
fileprivate let buttonServiceUuid = CBUUID(baseUuid: tiBaseUuid, shortUuid: buttonServiceShortUuid)
fileprivate let leftButtonUuid = CBUUID(baseUuid: tiBaseUuid, shortUuid: leftButtonShortUuid)
fileprivate let rightButtonUuid = CBUUID(baseUuid: tiBaseUuid, shortUuid: rightButtonShortUuid)

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
        guard (permission & kPermitRead) == kPermitRead else { return }
        
        bleService.read(suuid: suuid, cuuid: cuuid)
    }
    
    func setNotify(state: Bool) {
        guard (permission & kPermitNotify) == kPermitNotify else { return }
        
        bleService.setNotify(suuid: suuid,
                             cuuid: cuuid,
                             state: state)
    }
    
    // Ble inbound default implementations
    mutating func writeConfirm() {
        didWrite = true
        publish()
        didWrite = false
    }
    
    mutating func notifyStateChanged(state: Bool) {
        isNotifying = state
        publish()
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
        guard (permission & kPermitWrite) == kPermitWrite else { return}
        
        self.value = value
        bleValue = value == false ? 0 : 1
        bleService.write(suuid: suuid,
                         cuuid: cuuid,
                         data: withUnsafeBytes(of: &bleValue, { Data($0) }),
                         response: response)
        if response == false {
            publish()
        }
    }
    
    // Ble inbound
    func valueChanged(data: Data) {
        guard let result = data.to(type: UInt8.self) else {
            os_log("ERROR: converting data", log: Log.model, type: .error)
            return
        }
        
        bleValue = result
        value = result == 0 ? false : true
        publish()
    }
    
    // Publication
    func publish() {
        nc.post(name: topic,
                object: BinaryPayload(value: value,
                                      isNotifying: isNotifying,
                                      didWrite: didWrite))
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
    private let leftButton: BinaryEntity
    private let rightButton: BinaryEntity
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
        leftButton = BinaryEntity(name: kEntityLeftButton,
                                  topic: .entityLeftButton,
                                  suuid: buttonServiceUuid,
                                  cuuid: leftButtonUuid,
                                  permission: kPermitRead | kPermitNotify,
                                  bleService: bleService,
                                  defaultValue: false)
        rightButton = BinaryEntity(name: kEntityRightButton,
                                   topic: .entityRightButton,
                                   suuid: buttonServiceUuid,
                                   cuuid: rightButtonUuid,
                                   permission: kPermitRead | kPermitNotify,
                                   bleService: bleService,
                                   defaultValue: false)
        lookUpByEntity = [kEntityRedLed : .binary(redLed),
                          kEntityGreenLed : .binary(greenLed),
                          kEntityLeftButton : .binary(leftButton),
                          kEntityRightButton : .binary(rightButton)
        ]
        lookUpByCharac = [redLedUuid : .binary(redLed),
                          greenLedUuid : .binary(greenLed),
                          leftButtonUuid : .binary(leftButton),
                          rightButtonUuid : .binary(rightButton)

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
                        self.redLed.get()
                        self.greenLed.get()
                        self.leftButton.get()
                        self.rightButton.get()
                        self.leftButton.setNotify(state: true)
                        self.rightButton.setNotify(state: true)
                        self.getRssi()
                }
            }})
        
        // Write confirm
        nc.addObserver(forName: .characWriteConfirm, object: nil, queue: nil, using: { notification in
            if let payload = notification.object as? CharacWriteConfirmPayload,
                let thisEntity = self.lookUpByCharac[payload.charac] {
                switch thisEntity {
                case .binary(var bin):
                    bin.writeConfirm()
                }
            }})
        // Charac notification state
        nc.addObserver(forName: .characNotifyStateChanged,
                       object: nil,
                       queue: nil,
                       using: { notification in
                        if let payload = notification.object as? CharacNotifyStateChangedPayload,
                            let thisEntity = self.lookUpByCharac[payload.charac] {
                            switch thisEntity {
                            case .binary(var bin):
                                bin.notifyStateChanged(state: payload.state)
                            }
                        }
        })
        // Charac value
        nc.addObserver(forName: .characValueChanged,
                       object: nil,
                       queue: nil,
                       using: { notification in
                        if let payload = notification.object as? CharacValueChangedPayload,
                            let thisEntity = self.lookUpByCharac[payload.charac] {
                            switch thisEntity {
                            case .binary(let bin):
                                bin.valueChanged(data: payload.data)
                            }
                        }
        })

        // RSSI value changed
        nc.addObserver(forName: .rssiValueChanged,
                       object: nil,
                       queue: nil,
                       using: { notification in
                        if let payload = notification.object as? RssiValueChangedPayload {
                            os_log("RSSI: %d", log: Log.model, type: .info, payload.value)     // Temporary for debugging
                            nc.post(name: .entityRSSI, object: IntegerPayload(value: payload.value,
                                                                              isNotifying: false,
                                                                              didWrite: false))
                        }
        })

    }

    // MARK: - Public (Internal) API
    //
    func get(entity: String) {
        guard let thisEntity = lookUpByEntity[entity], bleStatus == .ready else { return }

        switch thisEntity {
        case .binary(let bin):
            bin.get()
        }
    }
    
    func set(entity: String, value: Bool, response: Bool) {
        guard let thisEntity = lookUpByEntity[entity], bleStatus == .ready else { return }

        switch thisEntity {
        case .binary(let bin):
            bin.set(value: value, response: response)
        }
    }
    
    func setNotify(entity: String, state: Bool) {
        guard let thisEntity = lookUpByEntity[entity], bleStatus == .ready else { return }

        switch thisEntity {
        case .binary(let bin):
            bin.setNotify(state: state)
        }
    }
    
    func getRssi() {
        // Make a direct call to BleService
        bleService.readRssi()
    }

}
