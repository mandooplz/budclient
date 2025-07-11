//
//  WorkFlow.swift
//  BudClient
//
//  Created by 김민우 on 7/11/25.
//
import Foundation


// MARK: WorkFlow
public enum WorkFlow: Sendable {
    @TaskLocal public static var id: ID = ID()
    
    
    // MARK: static method
    public static func with(_ id: WorkFlow.ID, task: @Sendable @escaping () async throws -> Void) async rethrows {
        try await WorkFlow.$id.withValue(id) {
            try await task()
        }
    }
    
    public static func create(location: String = "", task: @Sendable @escaping () async throws -> Void) async rethrows {
        let newWorkFlow = WorkFlow.ID()

        try await WorkFlow.$id.withValue(newWorkFlow) {
            let logger = WorkFlow.getLogger(for: location)
            logger.start()
            try await task()
        }
    }
    
    public static func getLogger(for category: String) -> BudLogger {
        .init(workflow: WorkFlow.id, category: category)
    }
    
    
    // MARK: value
    public struct ID: Sendable, Hashable, CustomStringConvertible {
        private let value: UUID
        public init(value: UUID = UUID()) {
            self.value = value
        }
        
        public var description: String {
            return value.uuidString.prefix(8).description
        }
    }
}


