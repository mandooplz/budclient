//
//  ActionSource.swift
//  BudClient
//
//  Created by 김민우 on 7/17/25.
//
import Foundation
import Values

private let logger = BudLogger("ActionSource")


// MARK: Object
@MainActor
package final class ActionSource: ActionSourceInterface {
    // MARK: core
    
    // MARK: state
    nonisolated let id = ID()
    
    // MARK: action
    
    // MARK: value
    @MainActor
    package struct ID: ActionSourceIdentity {
        let value = UUID()
        nonisolated init() { }
        
        package var isExist: Bool {
            ActionSourceManager.container[self] != nil
        }
        package var ref: ActionSource? {
            ActionSourceManager.container[self]
        }
    }
}


// MARK: ObjectManager
@MainActor
fileprivate final class ActionSourceManager: Sendable {
    // MARK: state
    fileprivate static var container: [ActionSource.ID: ActionSource] = [:]
    fileprivate static func register(_ object: ActionSource) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: ActionSource.ID) {
        container[id] = nil
    }
}

