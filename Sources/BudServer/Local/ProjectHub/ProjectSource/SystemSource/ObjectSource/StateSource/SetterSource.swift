//
//  SetterSource.swift
//  BudClient
//
//  Created by 김민우 on 7/17/25.
//
import Foundation
import Values

private let logger = BudLogger("SetterSource")


// MARK: Object
@MainActor
package final class SetterSource: Sendable {
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
            SetterSourceManager.container[self] != nil
        }
        package var ref: SetterSource? {
            SetterSourceManager.container[self]
        }
    }
}


// MARK: ObjectManager
@MainActor
fileprivate final class SetterSourceManager: Sendable {
    // MARK: state
    fileprivate static var container: [SetterSource.ID: SetterSource] = [:]
    fileprivate static func register(_ object: SetterSource) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: SetterSource.ID) {
        container[id] = nil
    }
}
