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
    private let workflow: WorkFlow.ID
    private let logger: Logger
    
    internal init(workflow: WorkFlow.ID, category: String) {
        self.workflow = workflow
        self.logger = Logger(subsystem: "Bud", category: category)
    }
    
    // MARK: operator
    internal func start() {
        logger.debug("[\(workflow)] start")
    }
    public func debug(_ routine: String, _ result: RoutineResult) {
        logger.debug("[\(workflow)] \(routine) \(result)")
    }
    public func error(_ routine: String, _ result: RoutineResult) {
        logger.error("[\(workflow)] \(routine) \(result)")
    }
    public func fault(_ routine: String, _ result: RoutineResult) {
        logger.fault("[\(workflow)] \(routine) \(result)")
    }
    
    // MARK: value
    public enum RoutineResult: CustomStringConvertible {
        case success
        case failure(reason: String)
        
        public var description: String {
            switch self {
            case .success:
                return "success"
            case .failure(let reason):
                return "failure(\(reason))"
            }
        }
    }
}
