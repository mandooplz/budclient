//
//  BudLogger.swift
//  BudClient
//
//  Created by 김민우 on 7/11/25.
//
import Foundation
import os


// MARK: BudLogger
public struct BudLogger: Sendable {
    // MARK: rawValue
    private let objectName: String
    private let logger: Logger
    init(objectName: String) {
        self.objectName = objectName
        self.logger = Logger(subsystem: "Bud", category: objectName)
    }
    
    
    // MARK: log
    static func start(_ workflow: WorkFlow.ID = WorkFlow.id) {
        Logger(subsystem: "Bud", category: "").debug("[\(workflow)] start")
    }
    
    static func end(_ workflow: WorkFlow.ID = WorkFlow.id) {
        Logger(subsystem: "Bud", category: "").debug("[\(workflow)] end")
    }
    
    public func start(_ description: String? = nil,
                      _ workflow: WorkFlow.ID = WorkFlow.id,
                      _ routine: String = #function) {
        
        if let description {
            logger.debug("[\(workflow)] ✅ \(objectName).\(routine) start\n\(description)")
        } else {
            logger.debug("[\(workflow)] ✅ \(objectName).\(routine) start")
        }
    }
    
    public func failure(_ description: String,
                        _ workflow: WorkFlow.ID = WorkFlow.id,
                        _ routine: String = #function) {
        logger.error("[\(workflow)] ⚠️ \(objectName).\(routine) failure\n\(description)")
    }
    
    public func failure(_ error: Error,
                        _ workflow: WorkFlow.ID = WorkFlow.id,
                        _ routine: String = #function) {
        self.failure(error, workflow, routine)
    }
    
    public func critical(_ description: String,
                         _ workflow: WorkFlow.ID = WorkFlow.id,
                         _ routine: String = #function) {
        logger.fault("[\(workflow)] ❌ \(objectName).\(routine) critical\n\(description)")
    }
    
    public func critical(_ error: Error,
                         _ workflow: WorkFlow.ID = WorkFlow.id,
                         _ routine: String = #function) {
        self.critical(error, workflow, routine)
    }
}
