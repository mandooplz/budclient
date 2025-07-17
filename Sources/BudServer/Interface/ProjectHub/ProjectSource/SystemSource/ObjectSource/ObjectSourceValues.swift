//
//  ObjectSourceValues.swift
//  BudClient
//
//  Created by 김민우 on 7/17/25.
//
import Foundation
import Values


// MARK: ObjectSourceEvent
package enum ObjectSourceEvent: Sendable {
    case modified(ObjectSourceDiff)
    case removed(ObjectSourceDiff)
    
    case addedState(StateSouce)
}


// MARK: ObjectSourceDiff
package struct ObjectSourceDiff: Sendable {
    package let id: any ObjectSourceIdentity
    package let target: ObjectID
    
    package let name: String
    package let role: ObjectRole
    
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
}
