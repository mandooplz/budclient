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
                        _ file: String = #file,      // 추가: 파일 경로
                        _ line: Int = #line,        // 추가: 줄 번호
                        _ routine: String = #function) { // 기존 #function
        
        // #file은 전체 파일 경로를 반환하므로, 파일 이름만 추출하여 사용하면 더 깔끔합니다.
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        
        logger.error("[\(workflow)] \(fileName):\(line) - \(objectName).\(routine) failure\n\(description)")
    }


    public func failure(_ error: Error,
                        _ workflow: WorkFlow.ID = WorkFlow.id,
                        _ file: String = #file,      // 추가
                        _ line: Int = #line,        // 추가
                        _ routine: String = #function) { // 추가
        // 다른 failure 함수를 호출할 때 file, line, routine 정보를 그대로 전달합니다.
        self.failure("\(error)", workflow, file, line, routine)
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

