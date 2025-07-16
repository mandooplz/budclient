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
    nonisolated var id: ID { get }
    
    func setName(_ value: String) async;
    
    func hasHandler(requester: ObjectID) async -> Bool
    func setHandler(requester: ObjectID, handler: Handler<ProjectSourceEvent>) async
    func removeHandler(requester: ObjectID) async;
    
    // MARK: action
    func createFirstSystem() async
    func remove() async
}


package protocol ProjectSourceIdentity: Sendable, Hashable {
    associatedtype Object: ProjectSourceInterface where Object.ID == Self
    
    var isExist: Bool { get async }
    var ref: Object? { get async }
}

