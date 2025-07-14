//
//  SystemSourceInterface.swift
//  BudClient
//
//  Created by 김민우 on 7/11/25.
//
import Foundation
import Values


// MARK: Interface
package protocol SystemSourceInterface: Sendable {
    associatedtype ID: SystemSourceIdentity where ID.Object == Self
    associatedtype RootSource: RootSourceInterface
    
    // MARK: state
    nonisolated var rootSourceRef: RootSource { get }
    
    func setName(_ value: String) async
    
    func hasHandler(requester: ObjectID) async -> Bool
    func setHandler(requester: ObjectID, handler: Handler<SystemSourceEvent>) async
    func removeHandler(requester: ObjectID) async
    
    func notifyNameChanged() async
    
    // MARK: action
    func addSystemRight() async
    func addSystemLeft() async
    func addSystemTop() async
    func addSystemBottom() async
    
    func createNewObject() async
    
    func remove() async
}

package protocol SystemSourceIdentity: Sendable, Hashable {
    associatedtype Object: SystemSourceInterface where Object.ID == Self
    
    var isExist: Bool { get async }
    var ref: Object? { get async }
}


// MARK: Value
package enum SystemSourceEvent: Sendable {
    case added(ObjectSourceDiff)
    case modified(ObjectSourceDiff)
    case removed(ObjectSourceDiff)
}


// MARK: ObjectSourceDiff
package struct ObjectSourceDiff: Sendable {
    package let id: any ObjectSourceIdentity
    package let target: ObjectID
    package let name: String
    
    @Server
    init(_ object: ObjectSourceMock) {
        self.id = object.id
        self.target = object.target
        self.name = object.name
    }
    
    init(id: any ObjectSourceIdentity,
         target: ObjectID,
         name: String) {
        self.id = id
        self.target = target
        self.name = name
    }
}


