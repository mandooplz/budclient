//
//  WorkflowID.swift
//  BudClient
//
//  Created by 김민우 on 7/17/25.
//
import Foundation

public struct WorkflowID: IDRepresentable {
    public let value: UUID
}


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
                
                try await WorkFlow.$id.withValue(newWorkflow) {
                    try await task()
                }
            }
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


// MARK: FlowID
public struct FlowID: IDRepresentable {
    public let value: UUID
}


