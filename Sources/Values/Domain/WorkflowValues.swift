//
//  WorkflowID.swift
//  BudClient
//
//  Created by 김민우 on 7/17/25.
//
import Foundation


// MARK: WorkflowID
public struct WorkflowID: IDRepresentable {
    public let value: UUID
    
    public init(_ value: UUID = UUID()) {
        self.value = value
    }
}


// MARK: FlowID
public struct FlowID: IDRepresentable {
    public let value: UUID
    
    public init(_ value: UUID = UUID()) {
        self.value = value
    }
}


