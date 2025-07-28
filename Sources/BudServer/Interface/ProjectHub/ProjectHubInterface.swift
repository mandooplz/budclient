//
//  ProjectHubInterface.swift
//  BudClient
//
//  Created by 김민우 on 7/10/25.
//
import Foundation
import Values


// MARK: Interface
package protocol ProjectHubInterface: Sendable, SyncInterface {
    associatedtype ID: ProjectHubIdentity where ID.Object == Self
    
    // MARK: state
    nonisolated var id: ID { get }
    
    func appendHandler(requester: ObjectID, _ handler: Handler<ProjectHubEvent>) async
    
    
    // MARK: action
    func createProject() async
}


package protocol ProjectHubIdentity: Sendable, Hashable {
    associatedtype Object: ProjectHubInterface where Object.ID == Self
    
    var isExist: Bool { get async }
    var ref: Object? { get async }
}


// MARK: Values
package enum ProjectHubEvent: Sendable {
    case projectAdded(ProjectSourceDiff)
}


