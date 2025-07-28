//
//  ProjectSourceInterface.swift
//  BudClient
//
//  Created by 김민우 on 7/11/25.
//
import Foundation
import Values


// MARK: Interface
package protocol ProjectSourceInterface: Sendable, SyncInterface {
    associatedtype ID: ProjectSourceIdentity where ID.Object == Self
    
    // MARK: state
    nonisolated var id: ID { get }
    
    func setName(_ value: String) async;
    
    func appendHandler(requester: ObjectID, _ handler: Handler<ProjectSourceEvent>) async
    
    
    // MARK: action
    func notifyStateChanged() async;
    
    func createSystem() async
    func removeProject() async
}


package protocol ProjectSourceIdentity: Sendable, Hashable {
    associatedtype Object: ProjectSourceInterface where Object.ID == Self
    
    var isExist: Bool { get async }
    var ref: Object? { get async }
}


// MARK: Values
package enum ProjectSourceEvent: Sendable {
    case modified(ProjectSourceDiff)
    case removed
    
    case systemAdded(SystemSourceDiff)
    case valueAdded(ValueSourceDiff)
}


package struct ProjectSourceDiff: Sendable {
    package let id: any ProjectSourceIdentity
    package let target: ProjectID
    package let name: String
    
    package let createdAt: Date
    package let updatedAt: Date
    package let order: Int
    
    // MARK: core
    package init(id: any ProjectSourceIdentity, target: ProjectID, name: String, createdAt: Date, updatedAt: Date, order: Int) {
        self.id = id
        self.target = target
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.order = order
    }
    
    @Server
    init(_ objectRef: ProjectSourceMock) {
        self.id = objectRef.id
        self.target = objectRef.target
        
        self.createdAt = objectRef.createdAt
        self.updatedAt = objectRef.updatedAt
        self.order = objectRef.order
        
        self.name = objectRef.name
    }
    
    // MARK: operator
    package func changeName(_ value: String) -> Self {
        .init(id: self.id,
              target: self.target,
              name: value,
              createdAt: self.createdAt,
              updatedAt: self.updatedAt,
              order: self.order)
    }
}

