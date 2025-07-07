//
//  ProjectHubEvent.swift
//  BudClient
//
//  Created by 김민우 on 7/3/25.
//


// MARK: ProjectHubEvent
package enum ProjectHubEvent: Sendable {
    case added(ProjectSourceID, ProjectID)
    case removed(ProjectSourceID)
}
