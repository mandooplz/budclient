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
    func setHandler(requester: ObjectID, user: UserID, handler: Handler<ProjectHubEvent>) async
    
    func notifyNameChanged(_: ProjectID) async;
    
    
    // MARK: action
    func createNewProject() async
}


package protocol ProjectHubIdentity: Sendable, Hashable {
    associatedtype Object: ProjectHubInterface where Object.ID == Self
    
    var isExist: Bool { get async }
    var ref: Object? { get async }
}


