//
//  WorkFlow.swift
//  BudClient
//
//  Created by 김민우 on 7/11/25.
//
import Foundation


// MARK: WorkFlow
public struct WorkFlow: Sendable {
    static let system = "Bud"
    @TaskLocal public static var id: ID = ID()
    
    
    // MARK: core
    @discardableResult
        public init(id: WorkFlow.ID? = nil, task: @Sendable @escaping () async throws -> Void) async rethrows {
            
            if let workflow = id {
                try await WorkFlow.$id.withValue(workflow) {
                    try await task()
                }
            } else {
                let newWorkflow = WorkFlow.ID(value: UUID())
                
                BudLogger.start(newWorkflow)
                try await WorkFlow.$id.withValue(newWorkflow) {
                    try await task()
                }
                BudLogger.end(newWorkflow)
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
}


