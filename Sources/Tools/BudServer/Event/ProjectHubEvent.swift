//
//  ProjectHubEvent.swift
//  BudClient
//
//  Created by 김민우 on 7/3/25.
//


package enum ProjectHubEvent: Sendable {
    case added(ProjectSourceID)
    case removed(ProjectSourceID)
    
    package typealias ProjectSourceID = String
}