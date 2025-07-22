//
//  ActionSourceMock.swift
//  BudClient
//
//  Created by 김민우 on 7/21/25.
//
import Foundation
import Values

private let logger = BudLogger("ActionSourceMock")


// MARK: Object
@Server
package final class ActionSourceMock: ActionSourceInterface {
    // MARK: core
    init(name: String,
         owner: ObjectSourceMock.ID) {
        self.name = name
        self.owner = owner
        
        ActionSourceMockManager.register(self)
    }
    func delete() {
        ActionSourceMockManager.unregister(self.id)
    }
    
    
    // MARK: state
    package nonisolated let id = ID()
    nonisolated let owner: ObjectSourceMock.ID
    nonisolated let target = ActionID()
    
    var name: String

    
    // MARK: action

    
    
    // MARK: value
    @Server
    package struct ID: ActionSourceIdentity {
        let value = UUID()
        nonisolated init() { }
        
        package var isExist: Bool {
            ActionSourceMockManager.container[self] != nil
        }
        package var ref: ActionSourceMock? {
            ActionSourceMockManager.container[self]
        }
    }
}


// MARK: ObjectManager
@Server
fileprivate final class ActionSourceMockManager: Sendable {
    // MARK: state
    fileprivate static var container: [ActionSourceMock.ID: ActionSourceMock] = [:]
    fileprivate static func register(_ object: ActionSourceMock) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: ActionSourceMock.ID) {
        container[id] = nil
    }
}
