//
//  RootStateSourceMock.swift
//  BudClient
//
//  Created by 김민우 on 7/15/25.
//
import Foundation
import Values


// MARK: Object
@Server
package final class RootStateSourceMock: RootStateSourceInterface {
    // MARK: core
    private typealias Manager = RootStateSourceMockManager
    
    
    // MARK: state
    package nonisolated let id = ID()
    
    
    // MARK: acton
    
    
    // MARK: value
    @Server
    package struct ID: RootStateSourceIdentity {
        package let value = UUID()
        nonisolated init() { }
        
        package var isExist: Bool {
            Manager.container[self] != nil
        }
        package var ref: RootStateSourceMock? {
            Manager.container[self]
        }
    }
}


// MARK: ObjectManager
@Server
fileprivate final class RootStateSourceMockManager: Sendable {
    // MARK: state
    fileprivate typealias Object = RootStateSourceMock
    fileprivate static var container: [Object.ID: Object] = [:]
    fileprivate static func register(_ object: Object) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: Object.ID) {
        container[id] = nil
    }
}
