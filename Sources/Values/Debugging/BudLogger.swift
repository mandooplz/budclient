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
    internal init(objectName: String) {
        self.objectName = objectName
        self.logger = Logger(subsystem: "Bud", category: objectName)
    }
    
    
    // MARK: log
    func start(_ workflow: WorkFlow.ID = WorkFlow.id) {
        logger.debug("[\(workflow)] 🚀 start")
    }
    
    func end(_ workflow: WorkFlow.ID = WorkFlow.id) {
        logger.debug("[\(workflow)] 💨 end")
    }
    
    public func success(_ info: Info? = nil,
                        _ workflow: WorkFlow.ID = WorkFlow.id,
                        _ routine: String = #function) {
        
        if let info {
            logger.debug("[\(workflow)] ✅ \(objectName).\(routine) success(\(info))")
        } else {
            logger.debug("[\(workflow)] ✅ \(objectName).\(routine) success")
        }
    }
    
    public func failure(_ info: Info,
                        _ workflow: WorkFlow.ID = WorkFlow.id,
                        _ routine: String = #function) {
        logger.error("[\(workflow)] ⚠️ \(objectName).\(routine) failure(\(info))")
    }
    
    public func failure(_ error: Error,
                        _ workflow: WorkFlow.ID = WorkFlow.id,
                        _ routine: String = #function) {
        self.failure(error.localizedDescription, workflow, routine)
    }
    
    public func critical(_ info: Info,
                         _ workflow: WorkFlow.ID = WorkFlow.id,
                         _ routine: String = #function) {
        logger.fault("[\(workflow)] 🚨 \(objectName).\(routine) critical(\(info))")
    }
    
    
    // MARK: value
    public typealias Info = String
}
