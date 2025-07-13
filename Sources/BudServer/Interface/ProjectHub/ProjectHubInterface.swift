//
//  ProjectHubInterface.swift
//  BudClient
//
//  Created by 김민우 on 7/10/25.
//
import Foundation
import Values


// MARK: Interface
package protocol ProjectHubInterface: Sendable {
    associatedtype ID: ProjectHubIdentity where ID.Object == Self
    
    // MARK: state
    nonisolated var id: ID { get }
    
    func insertTicket(_: CreateProject) async;
    
    func hasHandler(requester: ObjectID) async -> Bool
    func setHandler(requester: ObjectID,
                    user: UserID,
                    handler: Handler<ProjectHubEvent>) async
    func removeHandler(requester: ObjectID) async;
    
    func notifyNameChanged(_: ProjectID) async;
    
    
    // MARK: action
    func createNewProject() async
}

package protocol ProjectHubIdentity: Sendable, Hashable {
    associatedtype Object: ProjectHubInterface where Object.ID == Self
    
    var isExist: Bool { get async }
    var ref: Object? { get async }
}


// MARK: Value
package struct ProjectID: Identity {
    package let value: UUID
    
    package init(value: UUID = UUID()) {
        self.value = value
    }
    
    package func encode() -> [String: Any] {
        return ["value": value]
    }
}


package enum ProjectHubEvent: Sendable {
    case added(ProjectSourceDiff)
    case modified(ProjectSourceDiff)
    case removed(ProjectSourceDiff)
}


package struct ProjectSourceDiff: Sendable {
    package let id: any ProjectSourceIdentity
    package let target: ProjectID
    package let name: String
    
    package init(id: any ProjectSourceIdentity, target: ProjectID, name: String) {
        self.id = id
        self.target = target
        self.name = name
    }
}


package struct CreateProject: Sendable, Hashable {
    package let creator: UserID
    package let target: ProjectID
    package let name: String
    
    package init(creator: UserID,
                target: ProjectID = ProjectID(),
                name: String) {
        self.creator = creator
        self.target = target
        self.name = name
    }
}
