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
}

//
// Statuses
//
internal enum BleStatus: CustomStringConvertible {
    case onLine
    case offLine
    case ready
    
    var description: String {
        switch self {
        case .offLine: return "off-line"
        case .onLine: return "on-line"
        case .ready: return "ready"
        }
    }
}

//
// Notification Payloads
//
internal struct BleStatusPayload {
    var status: BleStatus
}

// Error management
//
internal enum BleError: Error {
    case UninitialisedProperty
    
    var description: String {
        switch self {
        case .UninitialisedProperty: return "Required property is nil"
        }
    }
}

// MARK: - BleService class
//
internal final class BleService: NSObject {
    
    private var centralManager: CBCentralManager?
    private let initOptions = [CBCentralManagerOptionShowPowerAlertKey : NSNumber(value: true)]
    // Queues
    private let cmdQueue = DispatchQueue(label: "com.iotcourse.cmdq", qos: .userInitiated)
    // State machine
    private var machine: Machine? = nil
    // State maps
    // TODO: state action map init - is an entry per state really needed? Can poss. init with [:]??
    private var stateActionMap: StateActionMap = Dictionary.init(uniqueKeysWithValues: BState.allCases.map { ($0, (nil, nil))})
    private var actionMap: ActionMap = Dictionary.init(uniqueKeysWithValues: BState.allCases.map { ($0, [:])})
    private var errorMap: ErrorMap = Dictionary.init(uniqueKeysWithValues: BState.allCases.map { ($0, (nil, .Start))})
    //
    private var attachingWith: (peripheral: CBPeripheral?, suuid: CBUUID?, isAttached: Bool) = (nil, nil, false)

    override init() {
        super.init()
        setupStateMaps()
        machine = Machine.init(actionMap: actionMap, stateActionMap: stateActionMap, errorMap: errorMap)
        centralManager = CBCentralManager(delegate: self,
                                          queue: DispatchQueue(label: "com.iotcourse.bleq",
                                                               qos: .userInitiated),
                                          options: initOptions)
    }

    // MARK: - Private functions
    //
    private func setupStateMaps() {
        
        // State action map
        stateActionMap[.Scanning] = (onEntry: performScan, onExit: nil)
        stateActionMap[.Ready] = (onEntry: performNotifyAttached, onExit: nil)
        
        // Action map
        actionMap[.Start]?[.OnLine] = (action: performNullAction, nextState: .Scanning)
        actionMap[.Start]?[.OffLine] = (action: performNullAction, nextState: nil)
        //
        actionMap[.Scanning]?[.ScanSuccess] = (action: performNullAction, nextState: .Ready)
        actionMap[.Scanning]?[.OffLine] = (action: performNullAction, nextState: .Start)
        //
        actionMap[.Ready]?[.OffLine] = (action: performNullAction, nextState: .Start)
        
        // Error map
        errorMap[.Scanning] = (action: performNullAction, nextState: .Start)
        errorMap[.Ready] = (action: performNullAction, nextState: .Ready)

    }
    
    private func handleEvent(event: BEvent) {
        if let mac = machine {
            mac.handleEvent(event: event)
        }
    }

    // MARK: - Public (Internal) API
    //
    func attachPeripheral(suuid: CBUUID) {
        
        attachingWith = (nil, suuid, false)
        cmdQueue.async { self.handleEvent(event: .OnLine) }
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

// MARK: - Actions
//
extension BleService {

    func performNullAction(event: BEvent, state: BState) {
        os_log("Trace: event %s, state %s", log: Log.ble, type: .info, event.description, state.description)
    }
    
    func performScan(event: BEvent, state: BState) throws {
        os_log("In performScan, event: %s state %s", log: Log.ble, type: .info, event.description, state.description)
        guard let cm = centralManager, let suuid = attachingWith.suuid else {
            throw BleError.UninitialisedProperty
        }
        
        attachingWith.peripheral = nil
        cm.scanForPeripherals(withServices: [suuid], options: nil)
    }

    func performConnect(event: BEvent, state: BState) throws {
        os_log("In performConnect, event: %s state %s", log: Log.ble, type: .info, event.description, state.description)
        guard let cm = centralManager, let per = attachingWith.peripheral else {
            throw BleError.UninitialisedProperty
        }
        
        cm.connect(per, options: nil)
    }

    func performNotifyAttached(thisEvent: BEvent, thisState: BState) {
        os_log("In performNotifyAttached, event: %s state: %s", log: Log.ble, type: .info, thisEvent.description, thisState.description)

        attachingWith.isAttached = true
        nc.post(name: .bleStatus, object: BleStatusPayload(status: .ready))
    }

}

// MARK: - CBCentralManagerDelegate
//
extension BleService: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        os_log("Central Manager state: %s", log: Log.ble, type: .info, central.state.description)
        
        var status: BleStatus
        
        switch central.state {
        case .poweredOn:
            status = .onLine
        case .poweredOff, .resetting, .unsupported, .unknown:
            status = .offLine
        case .unauthorized:     // iOS 13+ requires user authorisation
             os_log("Bluetooth unauthorised - set authorisation in Info.plist", log: Log.ble, type: .error, central.state.description)
             assertionFailure()
             status = .offLine
         @unknown default:
             os_log("Unknown central state - verify valid states for this iOS version", log: Log.ble, type: .error, central.state.description)
             assertionFailure()
             status = .offLine
         }
        
        nc.post(name: .bleStatus, object: BleStatusPayload(status: status))
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        os_log("In didDiscoverPeripheral: %s", log: Log.ble, type: .info, peripheral.identifier.uuidString)

        central.stopScan()

        if attachingWith.peripheral == nil {        // Discard duplicate discoveries
            peripheral.delegate = self
            attachingWith.peripheral = peripheral
            cmdQueue.async { self.handleEvent(event: .ScanSuccess) }
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        os_log("In didConnect: %s", log: Log.ble, type: .info, peripheral.identifier.uuidString)

    }

}

// MARK: - CBPeripheralDelegate
//
extension BleService: CBPeripheralDelegate {
    //
}

// MARK: - State Machine
//
// MARK: State Map Aliases
//
typealias StateActionMap = Dictionary<BState, (onEntry: ((BEvent, BState) throws ->())?, onExit: ((BEvent, BState) throws ->())?)>
typealias ActionMap = Dictionary<BState, Dictionary<BEvent, (action: ((BEvent, BState) throws ->())?, nextState: BState?)>>
typealias ErrorMap = Dictionary<BState, (action: ((BEvent, BState) -> ())?, nextState: BState)>

// MARK: State, Event, Action Enumerations
//

//
// Valid states
//
enum BState: Int, CaseIterable {
    case Start
    case Scanning
    case Ready
}

extension BState: CustomStringConvertible {

    var description: String {
        switch self {
        case .Start: return "Start"
        case .Scanning: return "Scanning"
        case .Ready: return "Ready"
        }
    }
}

//
// Valid events
//
enum BEvent {
    case OnLine             // Bluetooth is powered on and available
    case OffLine            // Bluetooth is not available (several possible reasons)
    case Scan
    case ScanSuccess
}

extension BEvent: CustomStringConvertible {

    var description: String {
        switch self {
        case .OnLine: return "OnLine"
        case .OffLine: return "OffLine"
        case .Scan: return "Scan"
        case .ScanSuccess: return "ScanSuccess"
        }
    }
}

// MARK: Class Machine
//

fileprivate final class Machine {
    private var stateActionMap: StateActionMap = [:]
    private var actionMap: ActionMap = [:]
    private var errorMap: ErrorMap = [:]
    private var currentState:BState? = .Start

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
    internal func handleEvent(event: BEvent) {
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
            errorMap[savedState]?.action?(event, savedState)
            currentState = errorMap[savedState]?.nextState
            assertionFailure("Invalid event \(event) for state \(savedState)")
            return
        }
        
        do {
            // Execute state exit action
            if let _ = tr.nextState {
                try stateActionMap[savedState]?.onExit?(event, savedState)
            }
            
            // Execute transition action
            try tr.action?(event, savedState)

            // Enter next state, execute entry action
            if let ns = tr.nextState  {
                currentState = ns
                try stateActionMap[ns]?.onEntry?(event, ns)
            }
            else { currentState = savedState }
        }
        catch {
            os_log("ERROR: %s, Event: %s, State: %s", log: Log.ble, type: .error,
                   error.localizedDescription, event.description, savedState.description)
            assertionFailure(error.localizedDescription)
            errorMap[savedState]?.action?(event, savedState)
            currentState = errorMap[savedState]?.nextState
        }
    }

}
