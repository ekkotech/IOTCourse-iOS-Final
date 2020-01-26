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
internal let kEntityLssOffOn        = "lssoffon"
internal let kEntityLssRgb          = "lssrgb"
internal let kEntityAlsLumin        = "alslumin"
internal let kEntityAlsThresh       = "alsthresh"
internal let kEntityAlsHyst         = "alshyst"
internal let kEntityAlsOffOn        = "alsoffon"

//
// Publication topics
//
public extension Notification.Name {
    static let entityRedLed = Notification.Name(kEntityRedLed)
    static let entityGreenLed = Notification.Name(kEntityGreenLed)
    static let entityLeftButton = Notification.Name(kEntityLeftButton)
    static let entityRightButton = Notification.Name(kEntityRightButton)
    static let entityRSSI = Notification.Name(kEntityRSSI)
    static let entityLssOffOn = Notification.Name(kEntityLssOffOn)
    static let entityLssRgb = Notification.Name(kEntityLssRgb)
    static let entityAlsLumin = Notification.Name(kEntityAlsLumin)
    static let entityAlsThresh = Notification.Name(kEntityAlsThresh)
    static let entityAlsHyst = Notification.Name(kEntityAlsHyst)
    static let entityAlsOffOn = Notification.Name(kEntityAlsOffOn)
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

internal struct Rgb {
    var red: Float
    var green: Float
    var blue: Float

    init(red: Float, green: Float, blue: Float) {
        self.red = red
        self.green = green
        self.blue = blue
    }
}

internal struct RgbPayload {
    var rgb: Rgb
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
// IOTCourse UUID’s
//
fileprivate let iotBaseUuid             = "775e0000-8aa0-40f6-b037-ea770326e665"
// Led String Service
fileprivate let lssServiceShortUuid     = "0100"
fileprivate let offOnShortUuid          = "0101"
fileprivate let rgbShortUuid            = "0102"
//
fileprivate let alsServiceShortUuid     = "0200"
fileprivate let luminShortUuid          = "0201"
fileprivate let threshShortUuid         = "0202"
fileprivate let hystShortUuid           = "0203"
fileprivate let lmOffOnShortUuid        = "0204"

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
//
// LSS Service
fileprivate let lssServiceUuid = CBUUID(baseUuid: iotBaseUuid, shortUuid: lssServiceShortUuid)
fileprivate let lssOffOnUuid = CBUUID(baseUuid: iotBaseUuid, shortUuid: offOnShortUuid)
fileprivate let lssRgbUuid = CBUUID(baseUuid: iotBaseUuid, shortUuid: rgbShortUuid)
//
// ALS Service
fileprivate let alsServiceUuid = CBUUID(baseUuid: iotBaseUuid, shortUuid: alsServiceShortUuid)
fileprivate let alsLuminUuid = CBUUID(baseUuid: iotBaseUuid, shortUuid: luminShortUuid)
fileprivate let alsThreshUuid = CBUUID(baseUuid: iotBaseUuid, shortUuid: threshShortUuid)
fileprivate let alsHystUuid = CBUUID(baseUuid: iotBaseUuid, shortUuid: hystShortUuid)
fileprivate let alsLmOffOnUuid = CBUUID(baseUuid: iotBaseUuid, shortUuid: lmOffOnShortUuid)
//
fileprivate let defaultService = lssServiceUuid

//
// Validation constants
// Threshold
internal let alsThreshMinValue = 10
internal let alsThreshMaxValue = 600
internal let alsThreshBleMinValue = UInt16(alsThreshMinValue)
internal let alsThreshBleMaxValue = UInt16(alsThreshMaxValue)
// Hysteresis
internal let alsHystMinValue = 1
internal let alsHystMaxValue = 10
internal let alsHystBleMinValue = UInt8(alsHystMinValue)
internal let alsHystBleMaxValue = UInt8(alsHystMaxValue)
// Luminance
internal let alsLuminMinValue = 0
internal let alsLuminMaxValue = 660
internal let alsLuminBleMinValue = UInt16(alsLuminMinValue)
internal let alsLuminBleMaxValue = UInt16(alsLuminMaxValue)

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

fileprivate protocol ValidatedEntity {
    associatedtype V
    associatedtype W
    
    var minValue: V { get set }
    var maxValue: V { get set }
    var bleMinValue: W { get set }
    var bleMaxValue: W { get set }
    
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

internal struct BleRgb: ExpressibleByIntegerLiteral {
    typealias IntegerLiteralType = Int
    
    var red: UInt8
    var green: UInt8
    var blue: UInt8
    
    init(integerLiteral hexRgb: IntegerLiteralType) {
        self.init(red: UInt8(hexRgb & 0x0000FF),
                  green: UInt8((hexRgb & 0x00FF00) >> 8),
                  blue: UInt8((hexRgb & 0xFF0000) >> 16))
    }
    
    init(red: UInt8, green: UInt8, blue: UInt8) {
        self.red = red
        self.green = green
        self.blue = blue
    }
}

fileprivate class RgbEntity: Entity {
    typealias T = Rgb
    typealias U = BleRgb
    
    let name: String
    let topic: Notification.Name
    var isNotifying: Bool = false
    var didWrite: Bool = false
    let suuid: CBUUID
    let cuuid: CBUUID
    let permission: UInt8
    let bleService: BleService
    let nc: NotificationCenter = NotificationCenter.default
    var value: T
    var bleValue: U

    init(name: String, topic: Notification.Name, suuid: CBUUID, cuuid: CBUUID, permission: UInt8, bleService: BleService, defaultValue: T) {
        self.name = name
        self.topic = topic
        self.suuid = suuid
        self.cuuid = cuuid
        self.permission = permission
        self.bleService = bleService
        self.value = defaultValue
        self.bleValue = BleRgb.init(red: UInt8(defaultValue.red) * UInt8.max,
                                    green: UInt8(defaultValue.green) * UInt8.max,
                                    blue: UInt8(defaultValue.blue) * UInt8.max)
    }
    
    // Client inbound
    func set(value: T, response: Bool) {
        guard (permission & kPermitWrite) == kPermitWrite else { return}
        
        self.value = value
        bleValue.red = UInt8(value.red * Float(UInt8.max))
        bleValue.green = UInt8(value.green * Float(UInt8.max))
        bleValue.blue = UInt8(value.blue * Float(UInt8.max))
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
        guard let result = data.to(type: BleRgb.self) else {
            os_log("ERROR: converting data", log: Log.model, type: .error)
            return
        }
        
        bleValue = result
        value.red = Float(bleValue.red) / Float(UInt8.max)
        value.green = Float(bleValue.green) / Float(UInt8.max)
        value.blue = Float(bleValue.blue) / Float(UInt8.max)
        publish()
    }
    
    // Publication
    func publish() {
        nc.post(name: topic,
                object: RgbPayload(rgb: value,
                                   isNotifying: isNotifying,
                                   didWrite: didWrite))
    }

}

fileprivate class IntegerEntity: Entity, ValidatedEntity {
    typealias T = Int
    typealias U = UInt16
    typealias V = T
    typealias W = U

    let name: String
    let topic: Notification.Name
    var isNotifying: Bool = false
    var didWrite: Bool = false
    let suuid: CBUUID
    let cuuid: CBUUID
    let permission: UInt8
    let bleService: BleService
    let nc: NotificationCenter = NotificationCenter.default
    var value: T
    var bleValue: U
    var minValue: V
    var maxValue: V
    var bleMinValue: W
    var bleMaxValue: W
    
    init(name: String, topic: Notification.Name, suuid: CBUUID, cuuid: CBUUID, permission: UInt8, bleService: BleService, defaultValue: T, minValue: V, maxValue: V, bleMinValue: W, bleMaxValue: W) {
        self.name = name
        self.topic = topic
        self.suuid = suuid
        self.cuuid = cuuid
        self.permission = permission
        self.bleService = bleService
        self.value = defaultValue
        self.bleValue = UInt16(defaultValue)
        self.minValue = minValue
        self.maxValue = maxValue
        self.bleMinValue = bleMinValue
        self.bleMaxValue = bleMaxValue
    }
    
    // Client inbound
    func set(value: T, response: Bool) {
        guard (permission & kPermitWrite) == kPermitWrite else { return}
        
        self.value = max(minValue, (min(maxValue, value)))
        bleValue = U(self.value)
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
        guard let result = data.to(type: U.self) else {
            os_log("ERROR: converting data", log: Log.model, type: .error)
            return
        }
        
        bleValue = max(bleMinValue, min(bleMaxValue, result))
        value = T(bleValue)
        publish()
    }
    
    // Publication
    func publish() {
        nc.post(name: topic,
                object: IntegerPayload(value: value,
                                   isNotifying: isNotifying,
                                   didWrite: didWrite))
    }
}

fileprivate class SmallIntegerEntity: Entity, ValidatedEntity {
    typealias T = Int
    typealias U = UInt8
    typealias V = T
    typealias W = U
    
    let name: String
    let topic: Notification.Name
    var isNotifying: Bool = false
    var didWrite: Bool = false
    let suuid: CBUUID
    let cuuid: CBUUID
    let permission: UInt8
    let bleService: BleService
    let nc: NotificationCenter = NotificationCenter.default
    var value: T
    var bleValue: U
    var minValue: V
    var maxValue: V
    var bleMinValue: W
    var bleMaxValue: W
    
    init(name: String, topic: Notification.Name, suuid: CBUUID, cuuid: CBUUID, permission: UInt8, bleService: BleService, defaultValue: T, minValue: V, maxValue: V, bleMinValue: W, bleMaxValue: W) {
        self.name = name
        self.topic = topic
        self.suuid = suuid
        self.cuuid = cuuid
        self.permission = permission
        self.bleService = bleService
        self.value = defaultValue
        self.bleValue = U(defaultValue)
        self.minValue = minValue
        self.maxValue = maxValue
        self.bleMinValue = bleMinValue
        self.bleMaxValue = bleMaxValue
    }
    
    // Client inbound
    func set(value: T, response: Bool) {
        guard (permission & kPermitWrite) == kPermitWrite else { return}
        
        self.value = max(minValue, min(maxValue, value))
        bleValue = U(self.value)
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
        guard let result = data.to(type: U.self) else {
            os_log("ERROR: converting data", log: Log.model, type: .error)
            return
        }
        
        bleValue = max(bleMinValue, min(bleMaxValue, result))
        value = T(bleValue)
        publish()
    }
    
    // Publication
    func publish() {
        nc.post(name: topic,
                object: IntegerPayload(value: value,
                                       isNotifying: isNotifying,
                                       didWrite: didWrite))
    }
}

//
// Entity Types
fileprivate enum EntityType {
    case binary(BinaryEntity)
    case rgb(RgbEntity)
    case integer(IntegerEntity)
    case smallInteger(SmallIntegerEntity)
}

//
// Valid Model Entity value types
protocol EntityValue {}

extension Bool: EntityValue {}
extension Rgb: EntityValue {}
extension Int: EntityValue {}

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
    private let offOn: BinaryEntity
    private let rgb: RgbEntity
    private let lumin: IntegerEntity
    private let thresh: IntegerEntity
    private let hyst: SmallIntegerEntity
    private let lmOffOn: BinaryEntity
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
        rgb = RgbEntity(name: kEntityLssRgb,
                        topic: .entityLssRgb,
                        suuid: lssServiceUuid,
                        cuuid: lssRgbUuid,
                        permission: kPermitRead | kPermitWrite,
                        bleService: bleService,
                        defaultValue: Rgb(red: 0.0, green: 0.0, blue: 0.0))
        offOn = BinaryEntity(name: kEntityLssOffOn,
                             topic: .entityLssOffOn,
                             suuid: lssServiceUuid,
                             cuuid: lssOffOnUuid,
                             permission: kPermitRead | kPermitWrite,
                             bleService: bleService,
                             defaultValue: false)
        lumin = IntegerEntity(name: kEntityAlsLumin,
                              topic: .entityAlsLumin,
                              suuid: alsServiceUuid,
                              cuuid: alsLuminUuid,
                              permission: kPermitRead | kPermitNotify,
                              bleService: bleService,
                              defaultValue: alsLuminMinValue,
                              minValue: alsLuminMinValue,
                              maxValue: alsLuminMaxValue,
                              bleMinValue: alsLuminBleMinValue,
                              bleMaxValue: alsLuminBleMaxValue)
        thresh = IntegerEntity(name: kEntityAlsThresh,
                               topic: .entityAlsThresh,
                               suuid: alsServiceUuid,
                               cuuid: alsThreshUuid,
                               permission: kPermitRead | kPermitWrite,
                               bleService: bleService,
                               defaultValue: alsThreshMinValue,
                               minValue: alsThreshMinValue,
                               maxValue: alsThreshMaxValue,
                               bleMinValue: alsThreshBleMinValue,
                               bleMaxValue: alsThreshBleMaxValue)
        hyst = SmallIntegerEntity(name: kEntityAlsHyst,
                                  topic: .entityAlsHyst,
                                  suuid: alsServiceUuid,
                                  cuuid: alsHystUuid,
                                  permission: kPermitRead | kPermitWrite,
                                  bleService: bleService,
                                  defaultValue: alsHystMinValue,
                                  minValue: alsHystMinValue,
                                  maxValue: alsHystMaxValue,
                                  bleMinValue: alsHystBleMinValue,
                                  bleMaxValue: alsHystBleMaxValue)
        lmOffOn = BinaryEntity(name: kEntityAlsOffOn,
                               topic: .entityAlsOffOn,
                               suuid: alsServiceUuid,
                               cuuid: alsLmOffOnUuid,
                               permission: kPermitRead | kPermitWrite,
                               bleService: bleService,
                               defaultValue: true)
        lookUpByEntity = [kEntityRedLed : .binary(redLed),
                          kEntityGreenLed : .binary(greenLed),
                          kEntityLeftButton : .binary(leftButton),
                          kEntityRightButton : .binary(rightButton),
                          kEntityLssRgb : .rgb(rgb),
                          kEntityLssOffOn : .binary(offOn),
                          kEntityAlsLumin : .integer(lumin),
                          kEntityAlsThresh : .integer(thresh),
                          kEntityAlsHyst : .smallInteger(hyst),
                          kEntityAlsOffOn : .binary(lmOffOn)
        ]
        lookUpByCharac = [redLedUuid : .binary(redLed),
                          greenLedUuid : .binary(greenLed),
                          leftButtonUuid : .binary(leftButton),
                          rightButtonUuid : .binary(rightButton),
                          lssRgbUuid : .rgb(rgb),
                          lssOffOnUuid : .binary(offOn),
                          alsLuminUuid : .integer(lumin),
                          alsThreshUuid : .integer(thresh),
                          alsHystUuid : .smallInteger(hyst),
                          alsLmOffOnUuid : .binary(lmOffOn)
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
                        self.getRssi()
                        self.rgb.get()
                        self.offOn.get()
                        self.lumin.get()
                        self.lumin.setNotify(state: true)
                        self.thresh.get()
                        self.hyst.get()
                        self.lmOffOn.get()
//                        self.redLed.get()
//                        self.greenLed.get()
//                        self.leftButton.get()
//                        self.rightButton.get()
//                        self.leftButton.setNotify(state: true)
//                        self.rightButton.setNotify(state: true)
                }
            }})
        
        // Write confirm
        nc.addObserver(forName: .characWriteConfirm, object: nil, queue: nil, using: { notification in
            if let payload = notification.object as? CharacWriteConfirmPayload,
                let thisEntity = self.lookUpByCharac[payload.charac] {
                switch thisEntity {
                case .binary(var bin):
                    bin.writeConfirm()
                case .rgb(var rgb):
                    rgb.writeConfirm()
                case .integer(var large):
                    large.writeConfirm()
                case .smallInteger(var small):
                    small.writeConfirm()
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
                            case .rgb(_):
                                break       // Not meaningful for rgb
                            case .integer(var large):
                                large.notifyStateChanged(state: payload.state)
                            case .smallInteger(var small):
                                small.notifyStateChanged(state: payload.state)
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
                            case .rgb(let rgb):
                                rgb.valueChanged(data: payload.data)
                            case .integer(let large):
                                large.valueChanged(data: payload.data)
                            case .smallInteger(let small):
                                small.valueChanged(data: payload.data)
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
        case .rgb(let rgb):
            rgb.get()
        case .integer(let large):
            large.get()
        case .smallInteger(let small):
            small.get()
        }
    }
    
    func set(entity: String, value: EntityValue, response: Bool) {
        guard let thisEntity = lookUpByEntity[entity], bleStatus == .ready else { return }

        switch thisEntity {
        case .binary(let bin):
            guard let val = value as? Bool else { return }
            bin.set(value: val, response: response)
        case .rgb(let rgb):
            guard let val = value as? Rgb else { return }
            rgb.set(value: val, response: response)
        case .integer(let large):
            guard let val = value as? Int else { return }
            large.set(value: val, response: response)
        case .smallInteger(let small):
            guard let val = value as? Int else { return }
            small.set(value: val, response: response)
        }
    }
    
    func setNotify(entity: String, state: Bool) {
        guard let thisEntity = lookUpByEntity[entity], bleStatus == .ready else { return }

        switch thisEntity {
        case .binary(let bin):
            bin.setNotify(state: state)
        case .rgb(_):
            break       // Not meaningful for rgb
        case .integer(let large):
            large.setNotify(state: state)
        case .smallInteger(let small):
            small.setNotify(state: state)
        }
    }
    
    func getRssi() {
        // Make a direct call to BleService
        bleService.readRssi()
    }

}
