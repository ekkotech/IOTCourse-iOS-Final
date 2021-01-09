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

internal let nc = NotificationCenter.default        // Application scope

// MARK: - Publication topics
//
public extension Notification.Name {
    static let bleStatus = Notification.Name("bleStatus")
    static let characWriteConfirm = Notification.Name("characWriteConfirm")
    static let characNotifyStateChanged = Notification.Name("characNotifyStateChanged")
    static let characValueChanged = Notification.Name("characValueChanged")
    static let rssiValueChanged = Notification.Name("rssiValueChanged")
    static let connectStatus = Notification.Name("connectStatus")
}

//
// Statuses
//
internal enum BleStatus: CustomStringConvertible {
    case onLine
    case offLine
    case ready
    case scanning
    case scanTimeout
    case retrieving
    case retrieveConnectFail
    case scanSuccess
    case retrieveSuccess
    case connected
    case disconnected
    case disconnectWithError
    
    var description: String {
        switch self {
        case .onLine: return "Bluetooth is on-line"
        case .offLine: return "Bluetooth is off-line"
        case .ready: return "Bluetooth is ready"
        case .scanning: return "Scanning..."
        case .scanTimeout: return "Scan timed out"
        case .retrieving: return "Retrieving..."
        case .retrieveConnectFail: return "Retrieve connect failed"
        case .scanSuccess: return "Discovered peripheral"
        case .retrieveSuccess: return "Retrieved peripheral"
        case .connected: return "Connected"
        case .disconnected: return "Disconnected"
        case .disconnectWithError: return "Disconnected with error"
        }
    }
}

//
// Notification Payloads
//
internal struct BleStatusPayload {
    var status: BleStatus
    var info: String?
}

internal struct CharacWriteConfirmPayload {
    var charac: CBUUID
}

internal struct CharacNotifyStateChangedPayload {
    var charac: CBUUID
    var state: Bool
}

internal struct CharacValueChangedPayload {
    var charac: CBUUID
    var data: Data
}

internal struct RssiValueChangedPayload {
    var value: Int
}

//
// Ble Commands
fileprivate enum BleCommand {
    case read
    case write(Data, CBCharacteristicWriteType)
    case setNotify(Bool)
    case readRSSI
}

fileprivate struct ActiveCommand {
    var suuid: CBUUID?
    var cuuid: CBUUID?
    var command: BleCommand = .read
}

//
// Timer parameters
//
fileprivate let kWatchdogTimeOut = TimeInterval(35.0)
fileprivate let scanTimeout             = TimeInterval(20.0)
fileprivate let connectAttemptTimeout   = TimeInterval(10.0)
fileprivate let connectionTimeout       = TimeInterval(10.0)
fileprivate let readRSSITimeout         = TimeInterval(0.5)

// Error management
//
internal enum BleError: Error {
    case UninitialisedProperty
    case InvalidPayload
    
    var description: String {
        switch self {
        case .UninitialisedProperty: return "Required property is nil"
        case .InvalidPayload: return "Invalid payload"
        }
    }
}

// MARK: - BleService class
//
internal final class BleService: NSObject {
    
    // Last attached peripheral
    private struct LastAttachedPeripheral: Codable {
        var peripheral: UUID
        var suuidData: Data
    }
    private let kLastAttachedPeripheralKey = "lap"
    private var ud: UserDefaults
    //
    private var centralManager: CBCentralManager?
    private let initOptions = [CBCentralManagerOptionShowPowerAlertKey : NSNumber(value: true)]
    // Queues
    private var opQueue = TimedOperationQueue(name: "com.iotcourse.opq",
                                              QoS: .userInitiated,
                                              timeout: kWatchdogTimeOut)
    private let cmdQueue = DispatchQueue(label: "com.iotcourse.cmdq", qos: .userInitiated)
    private let eventTimer = EventTimer()
    // State machine
    private var machine: Machine? = nil
    // State maps
    // TODO: state action map init - is an entry per state really needed? Can poss. init with [:]??
    private var stateActionMap: StateActionMap = Dictionary.init(uniqueKeysWithValues: BState.allCases.map { ($0, (nil, nil))})
    private var actionMap: ActionMap = Dictionary.init(uniqueKeysWithValues: BState.allCases.map { ($0, [:])})
    private var errorMap: ErrorMap = Dictionary.init(uniqueKeysWithValues: BState.allCases.map { ($0, (nil, .OnLine))})
    //
    private var attachingWith: (peripheral: CBPeripheral?, suuid: CBUUID?, isAttached: Bool) = (nil, nil, false)
    private var activeCommand = ActiveCommand()
    private var activeNotifications: [CBUUID : CBUUID] = [:]

    init(defaults: UserDefaults = UserDefaults.standard) {
        ud = defaults
        super.init()
        setupStateMaps()
        machine = Machine.init(actionMap: actionMap, stateActionMap: stateActionMap, errorMap: errorMap)
        centralManager = CBCentralManager(delegate: self,
                                          queue: DispatchQueue(label: "com.iotcourse.bleq",
                                                               qos: .userInitiated),
                                          options: initOptions)
        opQueue.maxConcurrentOperationCount = 1     // Serial queue
        os_log("BleService initialised", log: Log.ble, type: .info)
    }

    // MARK: - Private functions
    //
    private func setupStateMaps() {
        
        // State action map
        stateActionMap[.OnLine] = (onEntry: performReset, onExit: nil)
        stateActionMap[.OffLine] = (onEntry: performReset, onExit: nil)
        stateActionMap[.Scanning] = (onEntry: performScan, onExit: nil)
        stateActionMap[.Retrieving] = (onEntry: performRetrieve, onExit: nil)
        stateActionMap[.Ready] = (onEntry: performStageOperation, onExit: nil)
        stateActionMap[.RWNotify] = (onEntry: performConnect, onExit: nil)
        stateActionMap[.ReadRSSI] = (onEntry: performConnect, onExit: nil)
        
        // Action map
        actionMap[.OnLine]?[.OnLine] = (action: [performNotifyOnLine], nextState: nil)
        actionMap[.OnLine]?[.Scan] = (action: [performNotifyScanning], nextState: .Scanning)
        actionMap[.OnLine]?[.Retrieve] = (action: [performNotifyRetrieving], nextState: .Retrieving)
        actionMap[.OnLine]?[.OffLine] = (action: [performNotifyOffLine], nextState: .OffLine)
        //
        actionMap[.OffLine]?[.OnLine] = (action: [performNotifyOnLine], nextState: .OnLine)
        actionMap[.OffLine]?[.OffLine] = (action: [performNotifyOffLine], nextState: .OffLine)
        actionMap[.OffLine]?[.Retrieve] = (action: [performNotifyOffLine], nextState: .OffLine)
        actionMap[.OffLine]?[.Scan] = (action: [performNotifyOffLine], nextState: .OffLine)
        //
        actionMap[.Scanning]?[.ScanSuccess] = (action: [performNotifyScanSuccess, performNotifyReady], nextState: .Ready)
        actionMap[.Scanning]?[.ScanTimeout] = (action: [performNotifyScanTimeout, performNotifyOnLine], nextState: .OnLine)
        actionMap[.Scanning]?[.OffLine] = (action: [performNotifyOffLine], nextState: .OffLine)
        //
        actionMap[.Retrieving]?[.RetrieveFail] = (action: [performNotifyScanning], nextState: .Scanning)
        actionMap[.Retrieving]?[.ConnectSuccess(nil)] = (action: [performNotifyRetrieveSuccess, performNotifyReady], nextState: .Ready)
        actionMap[.Retrieving]?[.ConnectFail] = (action: [performNotifyScanning], nextState: .Scanning)
        actionMap[.Retrieving]?[.Disconnected] = (action: [performNotifyScanning], nextState: .Scanning)
        actionMap[.Retrieving]?[.OffLine] = (action: [performNotifyOffLine], nextState: .OffLine)
        //
        actionMap[.Ready]?[.Write] = (action: [performNullAction], nextState: .RWNotify)
        actionMap[.Ready]?[.SetNotify] = (action: [performNullAction], nextState: .RWNotify)
        actionMap[.Ready]?[.Read] = (action: [performNullAction], nextState: .RWNotify)
        actionMap[.Ready]?[.ReadRSSI] = (action: [performNullAction], nextState: .ReadRSSI)
        actionMap[.Ready]?[.OffLine] = (action: [performNotifyOffLine], nextState: .OffLine)
        actionMap[.Ready]?[.Disconnected] = (action: [performNotifyDisconnected], nextState: nil)
        actionMap[.Ready]?[.DisconnectedWithError] = (action: [performNotifyDisconnected], nextState: nil)
        actionMap[.Ready]?[.Scan] = (action: [performNotifyScanning], nextState: .Scanning)
        actionMap[.Ready]?[.Retrieve] = (action: [performNotifyRetrieving], nextState: .Scanning)
        //
        actionMap[.RWNotify]?[.ConnectSuccess(nil)] = (action: [performNotifyConnected, performDiscoverServices], nextState: nil)
        actionMap[.RWNotify]?[.DiscoverServicesSuccess(nil)] = (action: [performDiscoverCharacteristics], nextState: nil)
        actionMap[.RWNotify]?[.DiscoverCharacteristicsSuccess(nil)] = (action: [performCommand], nextState: .Ready)
        actionMap[.RWNotify]?[.ConnectFail] = (action: [performNotifyDisconnected], nextState: .Ready)
        actionMap[.RWNotify]?[.DiscoverServicesFail] = (action: [performNullAction], nextState: .Ready)
        actionMap[.RWNotify]?[.DiscoverCharacteristicsFail] = (action: [performNullAction], nextState: .Ready)
        actionMap[.RWNotify]?[.Disconnected] = (action: [performNotifyDisconnected], nextState: .Ready)
        actionMap[.RWNotify]?[.DisconnectedWithError] = (action: [performNotifyDisconnected], nextState: .Ready)
        actionMap[.RWNotify]?[.OffLine] = (action: [performNotifyOffLine], nextState: .OffLine)
        //
        actionMap[.ReadRSSI]?[.ConnectSuccess(nil)] = (action: [performNotifyConnected, performReadRSSI], nextState: .Ready)
        actionMap[.ReadRSSI]?[.ConnectFail] = (action: [performNotifyDisconnected], nextState: .Ready)
        actionMap[.ReadRSSI]?[.Disconnected] = (action: [performNotifyDisconnected], nextState: .Ready)
        actionMap[.ReadRSSI]?[.DisconnectedWithError] = (action: [performNotifyDisconnected], nextState: .Ready)
        actionMap[.ReadRSSI]?[.OffLine] = (action: [performNotifyOffLine], nextState: .OffLine)

        // Error map
        errorMap[.OnLine] = (action: performNullAction, nextState: .OnLine)
        errorMap[.OffLine] = (action: performNullAction, nextState: .OnLine)
        errorMap[.Scanning] = (action: performNullAction, nextState: .OnLine)
        errorMap[.Retrieving] = (action: performNullAction, nextState: .OnLine)
        errorMap[.Ready] = (action: performNullAction, nextState: .Ready)
        errorMap[.RWNotify] = (action: performNullAction, nextState: .Ready)
        errorMap[.ReadRSSI] = (action: performNullAction, nextState: .Ready)

    }
    
    private func handleEvent(event: BEvent, info: String?) {
        if let mac = machine {
            mac.handleEvent(event: event, info: info)
        }
    }

    private func setLastAttachedPeripheral(defaults: UserDefaults, peripheral: CBPeripheral, suuid: CBUUID) {
        let last = LastAttachedPeripheral(peripheral: peripheral.identifier, suuidData: suuid.data)
        defaults.set(try? JSONEncoder().encode(last), forKey: kLastAttachedPeripheralKey)
    }

    private func getLastAttachedPeripheral(defaults: UserDefaults) -> LastAttachedPeripheral? {
        var retValue: LastAttachedPeripheral? = nil
        if let lapData = defaults.object(forKey: kLastAttachedPeripheralKey) as? Data {
            retValue = try? JSONDecoder().decode(LastAttachedPeripheral.self, from: lapData)
        }
        return retValue
    }
    
    private func completeOperation() {
        if let aop = opQueue.operations.first as? AppOperation {
            aop.isExecuting = false
            aop.isFinished = true
        }
    }

    private func reestablishNotifications() {
        if let per = attachingWith.peripheral, per.state != .connected {
            activeNotifications.forEach { noti in
                opQueue.addOperation(AppOperation(queue: cmdQueue,
                                                  dispatchBlock: {
                                                    self.activeCommand = ActiveCommand(suuid: noti.key,
                                                                                       cuuid: noti.value,
                                                                                       command: .setNotify(true))
                                                    self.cmdQueue.async { self.handleEvent(event: .SetNotify, info: nil) }
                }))
            }
        }
    }
    
    private func clearBleState() {
        attachingWith = (nil, nil, false)
        activeCommand = ActiveCommand(suuid: nil, cuuid: nil, command: .read)
    }
    
    private func clearCommandQueue() {
        for op in opQueue.operations {
            if let aop = op as? AppOperation {
                aop.isExecuting = false
                aop.isFinished = true
            }
        }
    }
        
    private func notifyBleStatus(status: BleStatus, info: String?) {
        nc.post(name: .bleStatus, object: BleStatusPayload(status: status, info: info))
    }
    
    // MARK: - Public (Internal) API
    //
    func attachPeripheral(suuid: CBUUID, forceScan: Bool = false) {
        
        attachingWith = (nil, suuid, false)
        cmdQueue.async { self.handleEvent(event: forceScan ? .Scan : .Retrieve, info: nil) }
    }
    
    func read(suuid: CBUUID, cuuid: CBUUID) {
        reestablishNotifications()
        opQueue.addOperation(AppOperation(queue: cmdQueue,
                                          dispatchBlock: {
                                            self.activeCommand = ActiveCommand(suuid: suuid,
                                                                          cuuid: cuuid,
                                                                          command: .read)
                                            self.cmdQueue.async { self.handleEvent(event: .Read, info: nil) }
        }))
    }
    
    func write(suuid: CBUUID, cuuid: CBUUID, data: Data, response: Bool) {
        reestablishNotifications()
        opQueue.addOperation(AppOperation(queue: cmdQueue,
                                          dispatchBlock: {
                                            self.activeCommand = ActiveCommand(suuid: suuid,
                                                                          cuuid: cuuid,
                                                                          command: .write(data, response == true ? .withResponse : .withoutResponse))
                                            self.cmdQueue.async { self.handleEvent(event: .Write, info: nil) }
        }))
    }
    
    func setNotify(suuid: CBUUID, cuuid: CBUUID, state: Bool) {
        if state { activeNotifications[suuid] = cuuid }
        else { activeNotifications.removeValue(forKey: suuid)}

        opQueue.addOperation(AppOperation(queue: cmdQueue,
                                          dispatchBlock: {
                                            self.activeCommand = ActiveCommand(suuid: suuid,
                                                                          cuuid: cuuid,
                                                                          command: .setNotify(state))
                                            self.cmdQueue.async { self.handleEvent(event: .SetNotify, info: nil) }
        }))
    }
    
    func readRssi() {
        opQueue.addOperation(AppOperation(queue: cmdQueue,
                                          dispatchBlock: {
                                            self.activeCommand = ActiveCommand(suuid: nil,
                                                                               cuuid: nil,
                                                                               command: .readRSSI)
                                            self.cmdQueue.async { self.handleEvent(event: .ReadRSSI, info: nil) }
        }))
    }

}

// MARK: - Actions
//
extension BleService {

    func performNullAction(event: BEvent, state: BState, info: String?) {
        os_log("Trace: event %s, state %s", log: Log.ble, type: .info, event.description, state.description)
    }
    
    func performScan(event: BEvent, state: BState, info: String?) throws {
        os_log("In performScan, event: %s state %s", log: Log.ble, type: .info, event.description, state.description)
        guard let cm = centralManager, let suuid = attachingWith.suuid else {
            throw BleError.UninitialisedProperty
        }
        
        attachingWith.peripheral = nil
        eventTimer.scheduleEvent(fromNow: scanTimeout,
                                 onTimeout: {
                                    os_log("Scan timed out", log: Log.ble, type: .info)
                                    cm.stopScan()
                                    self.cmdQueue.async { self.handleEvent(event: .ScanTimeout, info: nil) }
                                    },
                                 onCancel: nil)
        cm.scanForPeripherals(withServices: [suuid], options: nil)
    }

    func performConnect(event: BEvent, state: BState, info: String?) throws {
        os_log("In performConnect, event: %s state %s", log: Log.ble, type: .info, event.description, state.description)
        guard let cm = centralManager, let per = attachingWith.peripheral else {
            throw BleError.UninitialisedProperty
        }
        
        eventTimer.scheduleEvent(fromNow: connectAttemptTimeout,
                                 onTimeout: {
                                    os_log("Connect attempt timed out", log: Log.ble, type: .info)
                                    cm.cancelPeripheralConnection(per)
                                    },
                                 onCancel: nil)
        cm.connect(per, options: nil)
    }

    func performStageOperation(event: BEvent, state: BState, info: String?) {
        os_log("In performStageOperation, event: %s state: %s", log: Log.ble, type: .info, event.description, state.description)

        if attachingWith.isAttached == false {
            attachingWith.isAttached = true
            if let per = attachingWith.peripheral, let suuid = attachingWith.suuid {
                setLastAttachedPeripheral(defaults: ud, peripheral: per, suuid: suuid)
            }
        }
        else {
            completeOperation()
        }
    }

    func performRetrieve(event: BEvent, state: BState, info: String?) throws {
        os_log("In performRetrieve, event: %s state %s", log: Log.ble, type: .info, event.description, state.description)
        guard let cm = centralManager, let suuid = attachingWith.suuid else {
            throw BleError.UninitialisedProperty }
        
        if let lap = getLastAttachedPeripheral(defaults: ud), CBUUID(data: lap.suuidData) == suuid {
            os_log("Retrieving...", log: Log.ble, type: .info)
            if let per = cm.retrievePeripherals(withIdentifiers: [lap.peripheral]).first {
                per.delegate = self
                attachingWith.peripheral = per
                eventTimer.scheduleEvent(fromNow: connectAttemptTimeout,
                                         onTimeout: {
                                            os_log("Connect attempt timed out", log: Log.ble, type: .info)
                                            cm.cancelPeripheralConnection(per)
                                            },
                                         onCancel: nil)
                cm.connect(per, options: nil)
            }
            else {
                cmdQueue.async { self.handleEvent(event: .RetrieveFail, info: nil) }
            }
        }
        else {
            cmdQueue.async { self.handleEvent(event: .RetrieveFail, info: nil) }
        }
    }

    func performDiscoverServices(event: BEvent, state: BState, info: String?) throws {
        os_log("In performDiscoverServices, event: %s state %s", log: Log.ble, type: .info, event.description, state.description)
        guard case BEvent.ConnectSuccess(let payload) = event, let pl = payload else {
            throw BleError.InvalidPayload }
        guard let suuid = activeCommand.suuid else {
            throw BleError.UninitialisedProperty }
                
        pl.peripheral.discoverServices([suuid])
    }

    func performDiscoverCharacteristics(event: BEvent, state: BState, info: String?) throws {
        os_log("In performDiscoverCharacteristics, event: %s state %s", log: Log.ble, type: .info, event.description, state.description)
        guard case BEvent.DiscoverServicesSuccess(let payload) = event, let pl = payload else {
            throw BleError.InvalidPayload }
        guard let cuuid = activeCommand.cuuid else {
            throw BleError.UninitialisedProperty }
        
        pl.peripheral.discoverCharacteristics([cuuid], for: pl.service)
    }

    func performCommand(event: BEvent, state: BState, info: String?) throws {
        os_log("In performCommand, event: %s state %s", log: Log.ble, type: .info, event.description, state.description)
        guard case BEvent.DiscoverCharacteristicsSuccess(let payload) = event, let pl = payload else {
            throw BleError.InvalidPayload }
            
            switch activeCommand.command {
            case .write(let data, let type):
                pl.peripheral.writeValue(data, for: pl.charac, type: type)
            case .setNotify(let state):
                pl.peripheral.setNotifyValue(state, for: pl.charac)
            case .read:
                pl.peripheral.readValue(for: pl.charac)
            default:
                break       // Complete other cases later...
            }
    }

    func performReadRSSI(event: BEvent, state: BState, info: String?) throws {
        os_log("In performReadRSSI, event: %s state %s", log: Log.ble, type: .info, event.description, state.description)
        guard case BEvent.ConnectSuccess(let payload) = event, let pl = payload else {
            throw BleError.InvalidPayload }
        
        pl.peripheral.readRSSI()
    }

    func performReset(event: BEvent, state: BState, info: String?) throws {
        os_log("In performReset, event: %s state %s", log: Log.ble, type: .info, event.description, state.description)

        clearBleState()
        clearCommandQueue()
    }
    
    /**
     A set of functions to publish BleStatus to upstream listeners.  BleStatus does not map 1-to-1 to BEvent; not all BEvents need to be published.
     */
    func performNotifyOnLine(event: BEvent, state: BState, info: String?) throws {
        os_log("In performNotifyOnLine, event: %s state %s", log: Log.ble, type: .info, event.description, state.description)
        notifyBleStatus(status: .onLine, info: info)
    }

    func performNotifyOffLine(event: BEvent, state: BState, info: String?) throws {
        os_log("In performNotifyOffLine, event: %s state %s", log: Log.ble, type: .info, event.description, state.description)
        notifyBleStatus(status: .offLine, info: info)
    }

    func performNotifyScanning(event: BEvent, state: BState, info: String?) throws {
        os_log("In performNotifyScanning, event: %s state %s", log: Log.ble, type: .info, event.description, state.description)
        notifyBleStatus(status: .scanning, info: info)
    }
    
    func performNotifyScanTimeout(event: BEvent, state: BState, info: String?) throws {
    os_log("In performNotifyScanTimeout, event: %s state %s", log: Log.ble, type: .info, event.description, state.description)
        notifyBleStatus(status: .scanTimeout, info: info)
    }
    
    func performNotifyScanSuccess(event: BEvent, state: BState, info: String?) throws {
    os_log("In performNotifyScanSuccess, event: %s state %s", log: Log.ble, type: .info, event.description, state.description)
        notifyBleStatus(status: .scanSuccess, info: info) // info == peripheral uuid
    }

    func performNotifyRetrieving(event: BEvent, state: BState, info: String?) throws {
    os_log("In performNotifyRetrieving, event: %s state %s", log: Log.ble, type: .info, event.description, state.description)
        notifyBleStatus(status: .retrieving, info: info)
    }
    
    func performNotifyRetrieveSuccess(event: BEvent, state: BState, info: String?) throws {
    os_log("In performNotifyRetrieveSuccess, event: %s state %s", log: Log.ble, type: .info, event.description, state.description)
        notifyBleStatus(status: .retrieveSuccess, info: info) // info == peripheral uuid
    }
    
    func performNotifyReady(event: BEvent, state: BState, info: String?) throws {
        os_log("In performNotifyReady, event: %s state %s", log: Log.ble, type: .info, event.description, state.description)
        notifyBleStatus(status: .ready, info: info)
    }
    
    func performNotifyConnected(event: BEvent, state: BState, info: String?) throws {
        os_log("In performNotifyConnected, event: %s state %s", log: Log.ble, type: .info, event.description, state.description)
        notifyBleStatus(status: .connected, info: info)
    }

    func performNotifyDisconnected(event: BEvent, state: BState, info: String?) throws {
        os_log("In performNotifyDisconnected, event: %s state %s", log: Log.ble, type: .info, event.description, state.description)
        notifyBleStatus(status: .disconnected, info: info)
    }

}

// MARK: - CBCentralManagerDelegate
//
extension BleService: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        os_log("Central Manager state: %s", log: Log.ble, type: .info, central.state.description)
        
        switch central.state {
        case .poweredOn:
            cmdQueue.async { self.handleEvent(event: .OnLine, info: nil) }
        case .poweredOff, .resetting, .unsupported, .unknown:
            cmdQueue.async { self.handleEvent(event: .OffLine, info: nil) }
        case .unauthorized:     // iOS 13+ requires user authorisation
             os_log("Bluetooth unauthorised - set authorisation in Info.plist", log: Log.ble, type: .error, central.state.description)
             assertionFailure()
             cmdQueue.async { self.handleEvent(event: .OffLine, info: nil) }
         @unknown default:
             os_log("Unknown central state - verify valid states for this iOS version", log: Log.ble, type: .error, central.state.description)
             assertionFailure()
             cmdQueue.async { self.handleEvent(event: .OffLine, info: nil) }
         }
        
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        os_log("In didDiscoverPeripheral: %s", log: Log.ble, type: .info, peripheral.identifier.uuidString)

        eventTimer.cancel()
        central.stopScan()

        if attachingWith.peripheral == nil {        // Discard duplicate discoveries
            peripheral.delegate = self
            attachingWith.peripheral = peripheral
            cmdQueue.async { self.handleEvent(event: .ScanSuccess, info: peripheral.identifier.uuidString) }
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        os_log("In didConnect: %s", log: Log.ble, type: .info, peripheral.identifier.uuidString)

        let timeout: TimeInterval
        if case BleCommand.readRSSI = activeCommand.command { timeout = readRSSITimeout }
        else { timeout = connectionTimeout }
         
        eventTimer.scheduleEvent(fromNow: timeout,
                                  onTimeout: {
                                     os_log("Connection timed out", log: Log.ble, type: .info)
                                     central.cancelPeripheralConnection(peripheral)
                                     },
                                  onCancel: nil)

        let payload = PPayload(peripheral: peripheral)
        cmdQueue.async { self.handleEvent(event: .ConnectSuccess(payload), info: peripheral.identifier.uuidString) }
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        os_log("In didFailToConnect: %s", log: Log.ble, type: .info, peripheral.identifier.uuidString)

        cmdQueue.async { self.handleEvent(event: .ConnectFail, info: nil) }
        
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        os_log("In didFailToConnect: %s", log: Log.ble, type: .info, peripheral.identifier.uuidString)

        if error == nil {
            // Intentional disconnect
            cmdQueue.async { self.handleEvent(event: .Disconnected, info: nil) }
        }
        else {
            // Unexpected disconnect
            os_log("Peripheral disconnected with error", log: Log.ble, type: .error)
            cmdQueue.async { self.handleEvent(event: .DisconnectedWithError, info: nil) }
        }
        
    }
}

// MARK: - CBPeripheralDelegate
//
extension BleService: CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil,
            let suuid = activeCommand.suuid,
            let svcs = peripheral.services,
            let thisSvce = (svcs.filter { $0.uuid == suuid }).first else {
                cmdQueue.async { self.handleEvent(event: .DiscoverServicesFail, info: nil) }
                return }
        
        let payload = PSPayload(peripheral: peripheral, service: thisSvce)
        cmdQueue.async { self.handleEvent(event: .DiscoverServicesSuccess(payload), info: nil) }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil,
            let cuuid = activeCommand.cuuid,
            let characs = service.characteristics,
            let thisCharac = (characs.filter { $0.uuid == cuuid }).first else {
                cmdQueue.async { self.handleEvent(event: .DiscoverCharacteristicsFail, info: nil) }
                return }
        
        let payload = PSCPayload(peripheral: peripheral, service: service, charac: thisCharac)
        cmdQueue.async { self.handleEvent(event: .DiscoverCharacteristicsSuccess(payload), info: nil) }
    }

    // MARK: Data Callbacks
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        os_log("In didWriteValueFor: %s", log: Log.ble, type: .info, characteristic.uuid.uuidString)
        guard error == nil else {
            os_log("ERROR: writing characteristic value", log: Log.ble, type: .error)
            return
        }
        
        nc.post(name: .characWriteConfirm,
                object: CharacWriteConfirmPayload(charac: characteristic.uuid))
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        os_log("In didUpdateNotificationStateFor: %s", log: Log.ble, type: .info, characteristic.uuid.uuidString)
        guard error == nil else {
            os_log("ERROR: updating notification state", log: Log.ble, type: .error)
            return
        }

        nc.post(name: .characNotifyStateChanged,
                object: CharacNotifyStateChangedPayload(charac: characteristic.uuid,
                                                        state: characteristic.isNotifying))

        if let cval = characteristic.value {
            nc.post(name: .characValueChanged,
                    object: CharacValueChangedPayload(charac: characteristic.uuid,
                                                      data: cval))
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        os_log("In didUpdateValueFor: %s", log: Log.ble, type: .info, characteristic.uuid.uuidString)
        guard error == nil else {
            os_log("ERROR: updating characteristic value", log: Log.ble, type: .error)
            return
        }
        
        if let cval = characteristic.value {
            nc.post(name: .characValueChanged,
                    object: CharacValueChangedPayload(charac: characteristic.uuid,
                                                      data: cval))
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        os_log("In didReadRSSI: %d", log: Log.ble, type: .info, RSSI.intValue)
        guard error == nil else {
            os_log("ERROR: reading RSSI", log: Log.ble, type: .error)
            return
        }
        
        nc.post(name: .rssiValueChanged,
                object: RssiValueChangedPayload(value: RSSI.intValue))
    }

}

// MARK: - State Machine
//
// MARK: State Map Aliases
//
typealias StateActionMap = Dictionary<BState, (onEntry: ((BEvent, BState, String?) throws ->())?, onExit: ((BEvent, BState, String?) throws ->())?)>
typealias ActionMap = Dictionary<BState, Dictionary<BEvent, (action: [((BEvent, BState, String?) throws ->())]?, nextState: BState?)>>
typealias ErrorMap = Dictionary<BState, (action: ((BEvent, BState, String?) -> ())?, nextState: BState)>

// MARK: State, Event, Action Enumerations
//

//
// Valid states
//
enum BState: Int, CaseIterable {
    case OnLine
    case OffLine
    case Scanning
    case Retrieving
    case Ready
    case RWNotify
    case ReadRSSI
}

extension BState: CustomStringConvertible {

    var description: String {
        switch self {
        case .OnLine: return "OnLine"
        case .OffLine: return "OffLine"
        case .Scanning: return "Scanning"
        case .Retrieving: return "Retrieving"
        case .Ready: return "Ready"
        case .RWNotify: return "RWNotify"
        case .ReadRSSI: return "ReadRSSI"
        }
    }
}

//
// Valid events
//
struct PPayload { var peripheral: CBPeripheral }
struct PSPayload { var peripheral: CBPeripheral; var service: CBService }
struct PSCPayload { var peripheral: CBPeripheral; var service: CBService; var charac: CBCharacteristic }

enum BEvent {
    case OnLine             // Bluetooth is powered on and available
    case OffLine            // Bluetooth is not available (several possible reasons)
    case Scan
    case ScanSuccess
    case ScanCancelled
    case ScanTimeout
    case Retrieve
    case RetrieveFail
    case RetrieveConnectFail
    case ConnectSuccess(PPayload?)
    case ConnectFail
    case ConnectAttemptTimeout
    case ConnectionTimeout
    case Disconnected
    case DisconnectedWithError
    case Read
    case Write
    case SetNotify
    case ReadRSSI
    case DiscoverServices
    case DiscoverServicesSuccess(PSPayload?)
    case DiscoverServicesFail
    case DiscoverCharacteristics
    case DiscoverCharacteristicsSuccess(PSCPayload?)
    case DiscoverCharacteristicsFail
    case Rescan

}

extension BEvent: CustomStringConvertible {

    var description: String {
        switch self {
        case .OnLine: return "OnLine"
        case .OffLine: return "OffLine"
        case .Scan: return "Scan"
        case .ScanSuccess: return "ScanSuccess"
        case .ScanCancelled: return "ScanCancelled"
        case .ScanTimeout: return "Scan Timeout"
        case .Retrieve: return "Retrieve"
        case .RetrieveFail: return "RetrieveFail"
        case .RetrieveConnectFail: return "RetrieveConnectFail"
        case .ConnectSuccess: return "Connect Success"
        case .ConnectFail: return "Connect Fail"
        case .ConnectAttemptTimeout: return "Connect Attempt Timeout"
        case .ConnectionTimeout: return "Connection Timeout"
        case .Disconnected: return "Disconnected"
        case .DisconnectedWithError: return "Disconnected With Error"
        case .Read: return "Read"
        case .Write: return "Write"
        case .SetNotify: return "Set Notify"
        case .ReadRSSI: return "Read RSSI"
        case .DiscoverServices: return "Discover Services"
        case .DiscoverServicesSuccess: return "Discover Services Success"
        case .DiscoverServicesFail: return "Discover Services Fail"
        case .DiscoverCharacteristics: return "Discover Characteristics"
        case .DiscoverCharacteristicsSuccess: return "Discover Characteristics Success"
        case .DiscoverCharacteristicsFail: return "Discover Characteristics Fail"
        case .Rescan: return "ReScan"
        }
    }
}

extension BEvent: Hashable {
    static func == (lhs: BEvent, rhs: BEvent) -> Bool {
        return lhs.hashValue == rhs.hashValue ? true : false
    }

    func hash(into hasher: inout Hasher) {

        switch self {
        case .OnLine: hasher.combine(0)
        case .OffLine: hasher.combine(1)
        case .Scan: hasher.combine(4)
        case .ScanSuccess: hasher.combine(5)
        case .ScanCancelled: hasher.combine(6)
        case .ScanTimeout: hasher.combine(7)
        case .Retrieve: hasher.combine(2)
        case .RetrieveFail: hasher.combine(3)
        case .ConnectSuccess: hasher.combine(8)
        case .ConnectFail: hasher.combine(9)
        case .ConnectAttemptTimeout: hasher.combine(10)
        case .ConnectionTimeout: hasher.combine(11)
        case .Disconnected: hasher.combine(12)
        case .DisconnectedWithError: hasher.combine(13)
        case .Read: hasher.combine(14)
        case .Write: hasher.combine(15)
        case .SetNotify: hasher.combine(16)
        case .ReadRSSI: hasher.combine(17)
        case .DiscoverServices: hasher.combine(18)
        case .DiscoverServicesSuccess: hasher.combine(19)
        case .DiscoverServicesFail: hasher.combine(20)
        case .DiscoverCharacteristics: hasher.combine(21)
        case .DiscoverCharacteristicsSuccess: hasher.combine(22)
        case .DiscoverCharacteristicsFail: hasher.combine(23)
        case .Rescan: hasher.combine(24)
        case .RetrieveConnectFail: hasher.combine(25)
        }
    }
}

// MARK: Class Machine
//

fileprivate final class Machine {
    private var stateActionMap: StateActionMap = [:]
    private var actionMap: ActionMap = [:]
    private var errorMap: ErrorMap = [:]
    private var currentState:BState? = .OnLine

    // MARK: Initialisation
    //
    init(actionMap: ActionMap, stateActionMap: StateActionMap, errorMap: ErrorMap) {
        self.actionMap = actionMap
        self.stateActionMap = stateActionMap
        self.errorMap = errorMap
    }

    // MARK: Private functions
    //
    /**
     Handle nested event error
     
     State machine concurrently processes two events.  Queueing should ensure that this condition never occurs.  However, in production, if this situation does occur, probably no option but to discard the event and continue
     */
    private func nilStateError() {
        assertionFailure("ERROR: Nested event")
        os_log("ERROR: Nested event", log: Log.ble, type: .error)
    }

    // MARK: Public (Internal) functions
    /**
     Performs state transition and error management
     
     Action Map rules:
     - For a given event:
      - absence of an entry signifies an invalid event for this state
      - a valid entry with a nil action signifies no transition action to be taken but state entry/exit action should be taken
      - a valid entry with a nil nextState signifies staying in the same state without executing state entry or exit actions

     State Action Map rules:
     - A valid dictionary entry defines the state entry and/or exit actions
     - Entry and/or exit actions only occur if actionMap.nextState != nil
     - Either action may be nil which signifies no action to be taken
     
     Error Map rules:
     - For each state, an error handling function and a next state are specified
                 
     */
    internal func handleEvent(event: BEvent, info: String?) {
        // Event processing cannot be nested
        // Ensure that machine is not currently processing an event
        guard let savedState = currentState else {
            nilStateError()
            return
        }
        
        // Execute actions while in the "nil state" state
        // This prevents processing nested events
        currentState = nil

        // Check for valid event for this state
        guard let tr = actionMap[savedState]?[event] else {
            errorMap[savedState]?.action?(event, savedState, info)
            currentState = errorMap[savedState]?.nextState
            assertionFailure("Invalid event \(event) for state \(savedState)")
            return
        }
        
        do {
            // Execute state exit action
            if let _ = tr.nextState {
                try stateActionMap[savedState]?.onExit?(event, savedState, info)
            }
            
            // Execute transition action
            if let tra = tr.action {
                try tra.forEach( { try $0(event, savedState, info) } )
            }

            // Enter next state, execute entry action
            if let ns = tr.nextState  {
                currentState = ns
                try stateActionMap[ns]?.onEntry?(event, ns, info)
            }
            else { currentState = savedState }
        }
        catch {
            os_log("ERROR: %s, Event: %s, State: %s", log: Log.ble, type: .error,
                   error.localizedDescription, event.description, savedState.description)
            assertionFailure(error.localizedDescription)
            errorMap[savedState]?.action?(event, savedState, info)
            currentState = errorMap[savedState]?.nextState
        }
    }

}
