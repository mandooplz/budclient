//
//  ProjectHubEvent.swift
//  BudClient
//
//  Created by 김민우 on 7/3/25.
//


// MARK: ProjectHubEvent
package enum ProjectHubEvent: Sendable {
    case added(ObjectID)
    case removed(ObjectID)
    // ProjectHubEvent는 ProjectSourceLink 자체를 전달해야 한다.
}
