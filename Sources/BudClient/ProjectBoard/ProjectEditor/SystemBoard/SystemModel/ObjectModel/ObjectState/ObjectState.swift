//
//  ObjectState.swift
//  BudClient
//
//  Created by 김민우 on 7/7/25.
//
import Foundation
import Values


// MARK: Object
@MainActor @Observable
public final class ObjectState: Sendable {
    // MARK: core
    init(target: StateID) {
        self.target = target
        
        ObjectStateManager.register(self)
    }
    func delete() {
        ObjectStateManager.unregister(self.id)
    }
    
    
    // MARK: state
    nonisolated let id = ID()
    nonisolated let target: StateID
    
    public var permission: StatePermission = .readWrite
    
    
    // MARK: action
    public func createGetter() async { }
    public func createSetter() async { }
    
    public func remove() { }
    
    
    // MARK: value
    @MainActor
    public struct ID: Sendable, Hashable {
        let value: UUID
        nonisolated init(value: UUID = UUID()) {
            self.value = value
        }
        
        var isExist: Bool {
            ObjectStateManager.container[self] != nil
        }
        public var ref: ObjectState? {
            ObjectStateManager.container[self]
        }
    }
}


// MARK: Objec Manager
@MainActor @Observable
fileprivate final class ObjectStateManager: Sendable {
    // MARK: state
    fileprivate static var container: [ObjectState.ID: ObjectState] = [:]
    fileprivate static func register(_ object: ObjectState) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: ObjectState.ID) {
        container[id] = nil
    }
}
