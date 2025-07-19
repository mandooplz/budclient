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



// MARK: Logger
public struct BudLogger: Sendable {
    private let logger: Logger
    public init(_ objectName: String) {
        self.logger = Logger(subsystem: "Bud", category: objectName)
    }
    
    public func start(_ file: String = #file,
                      _ line: Int = #line,
                      _ routine: String = #function) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        
        logger.debug("\(fileName):\(line) - \(routine) start")
    }
    
    public func end(_ description: String? = nil,
                    _ file: String = #file,
                    _ line: Int = #line,
                    _ routine: String = #function) {
        
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        
        logger.debug("\(fileName):\(line) - \(routine) \(description ?? "ended")")
    }
    
    public func failure(_ description: String,
                        _ file: String = #file,      // 추가: 파일 경로
                        _ line: Int = #line,        // 추가: 줄 번호
                        _ routine: String = #function) { // 기존 #function
        
        // #file은 전체 파일 경로를 반환하므로, 파일 이름만 추출하여 사용하면 더 깔끔합니다.
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        
        logger.error("[\(fileName):\(line) - \(routine) failure\n\(description)")
    }
    
    public func failure(_ error: Error,
                 _ file: String = #file,      // 추가
                 _ line: Int = #line,        // 추가
                 _ routine: String = #function) { // 추가
        // 다른 failure 함수를 호출할 때 file, line, routine 정보를 그대로 전달합니다.
        self.failure("\(error)", file, line, routine)
    }
    
}
