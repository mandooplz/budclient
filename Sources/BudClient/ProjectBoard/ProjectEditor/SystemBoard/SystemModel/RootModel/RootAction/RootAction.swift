//
//  RootAction.swift
//  BudClient
//
//  Created by 김민우 on 7/9/25.
//
import Foundation
import Values
import BudServer


// MARK: Object
@MainActor @Observable
public final class RootAction: Sendable {
    // MARK: core
    init(target: ActionID) {
        self.target = target
        
        RootActionManager.register(self)
    }
    func delete() {
        RootActionManager.unregister(self.id)
    }
    
    
    // MARK: state
    nonisolated let id = ID()
    nonisolated let target: ActionID
    
    
    // MARK: action
    
    
    
    // MARK: value
    @MainActor
    public struct ID: Sendable, Hashable {
        let value: UUID
        nonisolated init(value: UUID = UUID()) {
            self.value = value
        }
        
        var isExist: Bool {
            RootActionManager.container[self] != nil
        }
        public var ref: RootAction? {
            RootActionManager.container[self]
        }
    }
}


// MARK: ObjectManager
@MainActor @Observable
fileprivate final class RootActionManager: Sendable {
    // MARK: state
    fileprivate static var container: [RootAction.ID: RootAction] = [:]
    fileprivate static func register(_ object: RootAction) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: RootAction.ID) {
        container[id] = nil
    }
}
