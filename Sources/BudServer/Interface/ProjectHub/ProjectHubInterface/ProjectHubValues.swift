//
//  ProjectHubValues.swift
//  BudClient
//
//  Created by 김민우 on 7/17/25.
//
import Foundation
import Values


// MARK: ProjectID
package struct ProjectID: Identity {
    package let value: UUID
    
    package init(value: UUID = UUID()) {
        self.value = value
    }
    
    package func encode() -> [String: Any] {
        return ["value": value]
    }
}


// MARK: ProjectHubEvent
package enum ProjectHubEvent: Sendable {
    case added(ProjectSourceDiff)
}

