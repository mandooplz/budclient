//
//  StateSource.swift
//  BudClient
//
//  Created by 김민우 on 7/17/25.
//
import Foundation
import Values


// MARK: Object
@MainActor
package final class StateSource: Sendable {
    // MARK: core
    
    // MARK: state
    nonisolated let id = ID()
    
    // MARK: action
    
    // MARK: value
    @MainActor
    package struct ID: Sendable, Hashable {
        let value = UUID()
        nonisolated init() { }
        
        package var isExist: Bool {
            StateSourceManager.container[self] != nil
        }
        package var ref: StateSource? {
            StateSourceManager.container[self]
        }
    }
}


// MARK: ObjectManager
@MainActor
fileprivate final class StateSourceManager: Sendable {
    // MARK: state
    fileprivate static var container: [StateSource.ID: StateSource] = [:]
    fileprivate static func register(_ object: StateSource) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: StateSource.ID) {
        container[id] = nil
    }
}
