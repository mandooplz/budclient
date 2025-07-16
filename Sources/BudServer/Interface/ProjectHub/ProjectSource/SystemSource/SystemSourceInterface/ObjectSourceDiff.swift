//
//  ObjectSourceDiff.swift
//  BudClient
//
//  Created by 김민우 on 7/15/25.
//
import Foundation
import Values


// MARK: Value
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
