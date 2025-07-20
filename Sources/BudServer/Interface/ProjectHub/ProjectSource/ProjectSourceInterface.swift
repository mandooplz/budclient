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
    
    func appendHandler(for requester: ObjectID, _ handler: Handler<ProjectSourceEvent>) async
    func removeHandler(of requester: ObjectID) async
    func synchronize(requester: ObjectID) async
    
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


// MARK: Values
public enum ProjectSourceEvent: Sendable {
    case modified(ProjectSourceDiff)
    case removed
    
    case added(SystemSourceDiff)
}


public struct ProjectSourceDiff: Sendable {
    package let id: any ProjectSourceIdentity
    package let target: ProjectID
    package let name: String
    
    // MARK: core
    package init(id: any ProjectSourceIdentity, target: ProjectID, name: String) {
        self.id = id
        self.target = target
        self.name = name
    }
    
    @Server
    init(_ projectSourceMockRef: ProjectSourceMock) {
        self.id = projectSourceMockRef.id
        self.target = projectSourceMockRef.target
        self.name = projectSourceMockRef.name
    }
    
    // MARK: operator
    package func changeName(_ value: String) -> Self {
        .init(id: self.id, target: self.target, name: value)
    }
}

