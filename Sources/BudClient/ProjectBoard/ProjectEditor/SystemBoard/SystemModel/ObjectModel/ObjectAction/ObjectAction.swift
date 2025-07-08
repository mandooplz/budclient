//
//  ObjectAction.swift
//  BudClient
//
//  Created by 김민우 on 7/7/25.
//
import Foundation
import Values


// MARK: Object
@MainActor @Observable
public final class ObjectAction: Sendable {
    // MARK: core
    init(target: ActionID) {
        self.target = target
        
        ObjectActionManager.register(self)
    }
    func delete() {
        ObjectActionManager.unregister(self.id)
    }
    
    
    // MARK: state
    nonisolated let id = ID()
    nonisolated let target: ActionID
    
    public var name: String?
    
    
    // MARK: action
    public func remove() { }
    
    
    // MARK: value
    @MainActor
    public struct ID: Sendable, Hashable {
        let value: UUID
        nonisolated init(value: UUID = UUID()) {
            self.value = value
        }
        
        var isExist: Bool {
            ObjectActionManager.container[self] != nil
        }
        public var ref: ObjectAction? {
            ObjectActionManager.container[self]
        }
    }
}


// MARK: Object Manager
@MainActor @Observable
fileprivate final class ObjectActionManager: Sendable {
    // MARK: state
    fileprivate static var container: [ObjectAction.ID: ObjectAction] = [:]
    fileprivate static func register(_ object: ObjectAction) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: ObjectAction.ID) {
        container[id] = nil
    }
}
