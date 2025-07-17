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
    func setHandler(_ handler: Handler<ProjectSourceEvent>) async
    
    func notifyNameChanged() async;
    
    // MARK: action
    func createSystem() async
    func removeProject() async
}


package protocol ProjectSourceIdentity: Sendable, Hashable {
    associatedtype Object: ProjectSourceInterface where Object.ID == Self
    
    var isExist: Bool { get async }
    var ref: Object? { get async }
}

