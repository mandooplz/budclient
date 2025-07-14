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
    init() {
        ObjectSourceMockManager.register(self)
    }
    func delete() {
        ObjectSourceMockManager.unregister(self.id)
    }
    
    
    // MARK: state
    package nonisolated let id = ID()
    
    
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
