//
//  ProjectHubEvent.swift
//  BudClient
//
//  Created by 김민우 on 7/3/25.
//


// MARK: ProjectHubEvent
package enum ProjectHubEvent: Sendable {
    case added(ProjectSourceID, ProjectID)
    case modified(ProjectSourceDiff)
    case removed(ProjectID)
}


// MARK: ProjectSourceDiff
package struct ProjectSourceDiff: Sendable {
    package let id: ProjectSourceID
    package let target: ProjectID
    package let name: String
    
    package init(id: ProjectSourceID, target: ProjectID, name: String) {
        self.id = id
        self.target = target
        self.name = name
    }
    
    package func getEvent() -> ProjectHubEvent {
        .modified(self)
    }
}
