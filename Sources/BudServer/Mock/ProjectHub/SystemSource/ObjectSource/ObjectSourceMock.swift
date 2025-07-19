//
//  ObjectSourceMock.swift
//  BudClient
//
//  Created by 김민우 on 7/11/25.
//
import Foundation
import Values


// MARK: Object
@Server
package final class ObjectSourceMock: ObjectSourceInterface {
    // MARK: core
    init(name: String,
         role: ObjectRole,
         parentRef: SystemSourceMock) {
        self.name = name
        self.role = role
        self.parentRef = parentRef
        
        ObjectSourceMockManager.register(self)
    }
    func delete() {
        ObjectSourceMockManager.unregister(self.id)
    }
    
    
    // MARK: state
    package nonisolated let id = ID()
    package nonisolated let parentRef: SystemSourceMock
    package nonisolated let target = ObjectID()
    
    package var name: String
    package nonisolated let role: ObjectRole
    
    package var handler: EventHandler?
    package func setHandler(_ handler: EventHandler) {
        self.handler = handler
    }
    
    
    // MARK: action

    
    
    // MARK: value
    @Server
    package struct ID: ObjectSourceIdentity {
        let value = UUID()
        nonisolated init() { }
        
        package var isExist: Bool {
            ObjectSourceMockManager.container[self] != nil
        }
        package var ref: ObjectSourceMock? {
            ObjectSourceMockManager.container[self]
        }
    }
    package typealias EventHandler = Handler<ObjectSourceEvent>
}


// MARK: ObjectManager
@Server
fileprivate final class ObjectSourceMockManager: Sendable {
    // MARK: state
    fileprivate static var container: [ObjectSourceMock.ID: ObjectSourceMock] = [:]
    fileprivate static func register(_ object: ObjectSourceMock) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: ObjectSourceMock.ID) {
        container[id] = nil
    }
}
