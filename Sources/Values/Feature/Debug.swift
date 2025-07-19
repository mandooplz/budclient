//
//  Debug.swift
//  BudClient
//
//  Created by 김민우 on 7/3/25.
//
import Foundation
import os


// MARK: Callback
public typealias Callback = @Sendable () async -> Void


// MARK: KnownIssue
public struct KnownIssue: IssueRepresentable {
    public let id = UUID()
    public let isKnown: Bool = true
    public let reason: String
    
    public init(reason: String) {
        self.reason = reason
    }
    
    public init<ObjectError: RawRepresentable<String>>(_ reason: ObjectError) {
        self.reason = reason.rawValue
    }
}


// MARK: UnknownIssue
public struct UnknownIssue: IssueRepresentable {
    public let id = UUID()
    public let isKnown: Bool = false
    public let reason: String
    
    public init(reason: String) {
        self.reason = reason
    }
    
    public init<ObjectError: Error>(_ reason: ObjectError) {
        self.reason = reason.localizedDescription
    }
}



// MARK: BudLogger
public struct BudLogger: Sendable {
    // MARK: rawValue
    private let objectName: String
    private let logger: Logger
    public init(_ objectName: String) {
        self.objectName = objectName
        self.logger = Logger(subsystem: "Bud", category: objectName)
    }
    
    public var raw: Logger {
        return self.logger
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
            logger.debug("[\(workflow)] \(objectName).\(routine) start\n\(description)")
        } else {
            logger.debug("[\(workflow)] \(objectName).\(routine) start")
        }
    }
    
    public func info(_ description: String? = nil,
                     _ workflow: WorkFlow.ID = WorkFlow.id,
                     _ routine: String = #function) {
        if let description {
            logger.debug("[\(workflow)] \(objectName).\(routine) INFO\n\(description)")
        } else {
            logger.debug("[\(workflow)] \(objectName).\(routine) INFO")
        }
    }
    
    public func finished(_ description: String? = nil,
                        _ workflow: WorkFlow.ID = WorkFlow.id,
                        _ routine: String = #function) {
        if let description {
            logger.debug("[\(workflow)] \(objectName).\(routine) finished\n\(description)")
        } else {
            logger.debug("[\(workflow)] \(objectName).\(routine) finished")
        }
    }
    
    public func failure(_ description: String,
                        _ workflow: WorkFlow.ID = WorkFlow.id,
                        _ routine: String = #function) {
        logger.error("[\(workflow)] \(objectName).\(routine) failure\n\(description)")
    }
    
    
    public func failure(_ error: Error,
                        _ workflow: WorkFlow.ID = WorkFlow.id,
                        _ routine: String = #function) {
        self.failure("\(error)", workflow, routine)
    }
    
    
    // MARK: Message
    public func getLog(_ description: String,
                          _ workflow: WorkFlow.ID = WorkFlow.id,
                          _ routine: String = #function) -> String {
        return "[\(workflow)] \(objectName).\(routine) critical\n\(description)"
    }
    
    public func getLog(_ error: Error,
                       _ workflow: WorkFlow.ID = WorkFlow.id,
                       _ routine: String = #function) -> String {
        return self.getLog("\(error)", workflow, routine)
    }
}

