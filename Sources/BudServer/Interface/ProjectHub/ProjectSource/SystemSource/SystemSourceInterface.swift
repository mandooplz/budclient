//
//  SystemSourceInterface.swift
//  BudClient
//
//  Created by 김민우 on 7/11/25.
//
import Foundation
import Values


// MARK: Interface
package protocol SystemSourceInterface: Sendable, SyncInterface {
    associatedtype ID: SystemSourceIdentity where ID.Object == Self
    
    // MARK: state
    func setName(_ value: String) async
    func appendHandler(requester: ObjectID, _ handler: Handler<SystemSourceEvent>) async;
    
    
    // MARK: action
    func notifyStateChanged() async;
    
    func addSystemRight() async
    func addSystemLeft() async
    func addSystemTop() async
    func addSystemBottom() async;
    
    func createRootObject() async
    
    func removeSystem() async
}


package protocol SystemSourceIdentity: Sendable, Hashable {
    associatedtype Object: SystemSourceInterface where Object.ID == Self
    
    var isExist: Bool { get async }
    var ref: Object? { get async }
}


// MARK: Values
public enum SystemSourceEvent: Sendable {
    case modified(SystemSourceDiff)
    case removed
    
    case objectAdded(ObjectSourceDiff)
    case flowAdded(FlowSourceDiff)
}


public struct SystemSourceDiff: Sendable {
    package let id: any SystemSourceIdentity
    package let target: SystemID
    
    package let createdAt: Date
    package let updatedAt: Date
    package let order: Int
    
    package let name: String
    package let location: Location
    
    // MARK: core
    package init(id: any SystemSourceIdentity, target: SystemID, createdAt: Date, updatedAt: Date, order: Int, name: String, location: Location) {
        self.id = id
        self.target = target
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.order = order
        self.name = name
        self.location = location
    }
    
    @Server
    init(_ object: SystemSourceMock) {
        self.id = object.id
        self.target = object.target
        self.createdAt = object.createdAt
        self.updatedAt = object.updatedAt
        self.order = object.order
        self.name = object.name
        self.location = object.location
    }
    
    
    // MARK: operator
    package func newName(_ value: String) -> Self {
        .init(id: self.id,
              target: self.target,
              createdAt: self.createdAt,
              updatedAt: self.updatedAt,
              order: self.order,
              name: value,
              location: self.location)
    }
    
    package func newLocation(_ value: Location) -> Self {
        .init(id: self.id,
              target: self.target,
              createdAt: self.createdAt,
              updatedAt: self.updatedAt,
              order: self.order,
              name: self.name,
              location: value)
    }
}

