//
//  ProjectHubEvent.swift
//  BudClient
//
//  Created by 김민우 on 7/15/25.
//
import Foundation
import Values


// MARK: Value
package enum ProjectHubEvent: Sendable {
    case added(ProjectSourceDiff)
    case modified(ProjectSourceDiff)
    case removed(ProjectSourceDiff)
}
