//
//  ObjectSourceValues.swift
//  BudClient
//
//  Created by 김민우 on 7/17/25.
//
import Foundation
import Values


// MARK: ObjectSourceEvent
public enum ObjectSourceEvent: Sendable {
    case modified(ObjectSourceDiff)
    case removed(ObjectSourceDiff)
    
    case addedState(StateSourceDiff)
}


// MARK: ObjectSourceDiff
public struct ObjectSourceDiff: Sendable {
    package let id: any ObjectSourceIdentity
    package let target: ObjectID
    
    package let name: String
    package let role: ObjectRole
    
    // MARK: core
    @Server
    init(_ object: ObjectSourceMock) {
        self.id = object.id
        self.target = object.target
        self.name = object.name
        self.role = object.role
    }
    
    init(id: any ObjectSourceIdentity,
         target: ObjectID,
         name: String,
         role: ObjectRole) {
        self.id = id
        self.target = target
        self.name = name
        self.role = role
    }
    
    
    // MARK: operator
    func newName(_ value: String) -> Self {
        .init(id: self.id, target: self.target, name: value, role: self.role)
    }
}



// MARK: StateSourceDiff
public struct StateSourceDiff: Sendable {
    
}
