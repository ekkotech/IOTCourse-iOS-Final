//
//  TimedOperation.swift
//  IOTCourse4
//
//  Created by Andrew Coad on 29/05/2019.
//  Copyright © 2019 IOTCourse4. All rights reserved.
//

import Foundation
import os

class TimedOperationQueue: OperationQueue {
    private let minTimeout: TimeInterval = 35.0  // Seconds
    private var timerTick: TimeInterval = 10.0   // Seconds
    private var numIterations: Int = 3
    private var iterationCount: Int = 0
    private var watchdog: Timer = Timer()
    private weak var lastOperation: AppOperation? = nil
    
    init(name: String, QoS: QualityOfService, timeout: TimeInterval) {
        super.init()
        self.name = name
        self.qualityOfService = QoS
        self.maxConcurrentOperationCount = 1        // Serial queue
        self.timerTick = timeout >= minTimeout ?
            (timeout / Double(numIterations)) :
            (minTimeout / Double(numIterations))
        self.watchdog = Timer.scheduledTimer(withTimeInterval: self.timerTick, repeats: true, block: handleTimeout)
    }
    
    private func handleTimeout(timer: Timer) {
        os_log("In %s handleTimeout - on queue: %d", log: Log.ble, type: .info, self.name ?? "TimedOperationQueue", operationCount)

        if let thisOperation = operations.first as? AppOperation {
            // Queue not empty
            if thisOperation == lastOperation {
                if iterationCount >= numIterations {
                    // Remove operation from queue
                    os_log("WARNING: Removing message from operation queue", log: Log.ble, type: .info)
                    thisOperation.isExecuting = false
                    thisOperation.isFinished = true
                    iterationCount = 0
                }
                else { iterationCount = iterationCount + 1 }
            }
            else {
                lastOperation = thisOperation
//                lastOperation = operations[0] as? AppOperation
                iterationCount = 0
            }
        }
        else {
            // Queue empty
            iterationCount = 0
            lastOperation = nil
        }
    }
}
