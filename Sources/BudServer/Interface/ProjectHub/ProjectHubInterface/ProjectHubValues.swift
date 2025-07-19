//
//  ProjectHubValues.swift
//  BudClient
//
//  Created by 김민우 on 7/17/25.
//
import Foundation
import Values


// MARK: ProjectID
public struct ProjectID: IDRepresentable {
    public let value: UUID
    
    public init(value: UUID = UUID()) {
        self.value = value
    }
    
    package func encode() -> [String: Any] {
        return ["value": value]
    }
}


// MARK: ProjectHubEvent
public enum ProjectHubEvent: Sendable {
    case added(ProjectSourceDiff)
}

