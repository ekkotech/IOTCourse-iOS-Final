//
//  AppOperation.swift
//  IOTCourse4
//
//  Created by Andrew Coad on 29/05/2019.
//  Copyright © 2019 IOTCourse4. All rights reserved.
//

import Foundation

class AppOperation: Operation {
    
    // MARK: - Private properties
    private var _isExecuting: Bool = false
    private var _isFinished: Bool = false
    private var _isCancelled: Bool = false
    
    // MARK: - Public properties
    public override var isAsynchronous: Bool { return true }
    public override var isConcurrent: Bool { return true }
    public override var isExecuting: Bool {
        get { return _isExecuting }
        set { willChangeValue(forKey: "isExecuting")
            _isExecuting = newValue
            didChangeValue(forKey: "isExecuting")
        }
    }
    public override var isFinished: Bool {
        get { return _isFinished }
        set { willChangeValue(forKey: "isFinished")
            _isFinished = newValue
            didChangeValue(forKey: "isFinished")
        }
    }
    public override var isCancelled: Bool {
        get { return _isCancelled }
        set { willChangeValue(forKey: "isCancelled")
            _isCancelled = newValue
            didChangeValue(forKey: "isCancelled")
        }
    }
    public var appQueue:DispatchQueue? = nil
    public var dispatchBlock:(()->())? = nil
    
    // MARK: - Public API
    init(queue: DispatchQueue, dispatchBlock: @escaping ()->()) {
        self.appQueue = queue
        self.dispatchBlock = dispatchBlock
    }
    
    override func start() {
        
        if isCancelled {
            isExecuting = false
            isFinished = true
            return
        }
        
        if let aq = appQueue, let db = dispatchBlock {
            self.isExecuting = true
            self.isFinished = false
            aq.async(execute: db)
        }
    }
    
    public func markAsDone() {
        isExecuting = false
        isFinished = true
    }
    
}
