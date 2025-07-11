//
//  UserFlow.swift
//  BudClient
//
//  Created by 김민우 on 7/11/25.
//
import Foundation


// MARK: UserFlow
public enum FlowGroup {
    @TaskLocal public static var id: UUID = UUID()
}


public func newFlowGroup(id: UUID = UUID(), operation: @Sendable @escaping () async throws -> Void) async rethrows {
    try await FlowGroup.$id.withValue(id) {
        try await operation()
    }
}

// logger.debug("[\(FlowGroup.id.uuidString.prefix(8))] ProjectBoard.subscribe() success")
