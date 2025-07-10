//
//  ProjectSourceInterface.swift
//  BudClient
//
//  Created by 김민우 on 7/11/25.
//
import Foundation
import Values


// MARK: Interface
package protocol ProjectSourceInterface: Sendable {
    associatedtype ID: ProjectSourceIdentity where ID.Object == Self
    
    // MARK: state
    func setName(_ value: String) async;
    
    func hasHandler(requester: ObjectID) async -> Bool
    func setHandler(requester: ObjectID, handler: Handler<ProjectSourceEvent>) async
    func removeHandler(requester: ObjectID) async;
    
    // MARK: action
    func createFirstSystem() async throws
    func remove() async
}


package protocol ProjectSourceIdentity: Sendable, Hashable {
    associatedtype Object: ProjectSourceInterface where Object.ID == Self
    
    var isExist: Bool { get async }
    var ref: Object? { get async }
}


// MARK: Value
package enum ProjectSourceEvent: Sendable {
    case added(SystemSourceDiff)
    case modified(SystemSourceDiff)
    case removed(SystemSourceDiff)
}


package struct SystemSourceDiff: Sendable {
    package let id: any SystemSourceIdentity
    package let target: SystemID
    package let name: String
    package let location: Location
    
    package init(id: any SystemSourceIdentity,
                 target: SystemID,
                 name: String,
                 location: Location) {
        self.id = id
        self.target = target
        self.name = name
        self.location = location
    }
    
    package func getEvent() -> ProjectSourceEvent {
        .modified(self)
    }
}


