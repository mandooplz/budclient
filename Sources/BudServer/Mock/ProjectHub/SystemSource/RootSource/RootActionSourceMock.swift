//
//  RootActionSourceMock.swift
//  BudClient
//
//  Created by 김민우 on 7/15/25.
//
import Foundation
import Values


// MARK: Object
@Server
package final class RootActionSourceMock: RootActionSourceInterface {
    // MARK: core
    private typealias Manager = RootActionSourceMockManager
    
    
    // MARK: state
    package nonisolated let id = ID()
    
    
    // MARK: action
    
    
    // MARK: value
    @Server
    package struct ID: RootActionSourceIdentity {
        package let value = UUID()
        nonisolated init() { }
        
        package var isExist: Bool {
            Manager.container[self] != nil
        }
        package var ref: RootActionSourceMock? {
            Manager.container[self]
        }
    }
}


// MARK: ObjectManager
@Server
fileprivate final class RootActionSourceMockManager: Sendable {
    // MARK: state
    fileprivate typealias Object = RootActionSourceMock
    fileprivate static var container: [Object.ID: Object] = [:]
    fileprivate static func register(_ object: Object) {
        self.container[object.id] = object
    }
    fileprivate static func unregister(_ id: Object.ID) {
        self.container[id] = nil
    }
}
