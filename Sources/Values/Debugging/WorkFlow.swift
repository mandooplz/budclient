//
//  WorkFlow.swift
//  BudClient
//
//  Created by 김민우 on 7/11/25.
//
import Foundation


// MARK: WorkFlow
public enum WorkFlow: Sendable {
    static let system = "Bud"
    @TaskLocal public static var id: ID = ID()
    
    
    // MARK: core
    public static func with(_ id: WorkFlow.ID, task: @Sendable @escaping () async throws -> Void) async rethrows {
        try await WorkFlow.$id.withValue(id) {
            try await task()
        }
    }
    
    public static func create(_ location: String = "", task: @Sendable @escaping () async throws -> Void) async rethrows {
        let newWorkFlow = WorkFlow.ID(value: UUID())

        try await WorkFlow.$id.withValue(newWorkFlow) {
            let logger = WorkFlow.getLogger(for: location)
            logger.start()
            try await task()
            logger.end()
        }
    }
    
    public static func getLogger(for objectName: String) -> BudLogger {
        .init(objectName: objectName)
    }
    
    
    // MARK: value
    public struct ID: Sendable, Hashable, CustomStringConvertible, Codable {
        public let value: UUID?
        public init(value: UUID? = nil) {
            self.value = value
        }
        
        public var description: String {
            if let value {
                return value.uuidString.prefix(8).description
            } else {
                return "--------"
            }
        }
    }
    
    public enum RoutineResult: CustomStringConvertible {
        case success(detail: String? = nil)
        case failure(reason: String)
        
        public var description: String {
            switch self {
            case .success(let detail):
                return "success\(detail ?? "")"
            case .failure(let reason):
                return "failure(\(reason))"
            }
        }
    }
}


