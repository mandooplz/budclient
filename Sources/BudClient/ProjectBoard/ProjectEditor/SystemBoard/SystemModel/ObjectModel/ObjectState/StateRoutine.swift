//
//  ObjectGetter.swift
//  BudClient
//
//  Created by 김민우 on 7/7/25.
//
import Foundation
import Values
import BudServer


// MARK: Object
@MainActor @Observable
public final class StateRoutine: Sendable {
    // MARK: core
    init(target: GetterID) {
        self.target = target
        
        StateRoutineManager.register(self)
    }
    func delete() {
        StateRoutineManager.unregister(self.id)
    }
    
    // MARK: state
    nonisolated let id = ID()
    nonisolated let target: GetterID
    
    
    // MARK: action
    public func remove() async { }
    
    
    // MARK: value
    @MainActor
    public struct ID: Sendable, Hashable {
        let value: UUID
        nonisolated init(value: UUID = UUID()) {
            self.value = value
        }
        
        var isExist: Bool {
            StateRoutineManager.container[self] != nil
        }
        public var ref: StateRoutine? {
            StateRoutineManager.container[self]
        }
    }
}


// MARK: Object Manager
@MainActor @Observable
fileprivate final class StateRoutineManager: Sendable {
    // MARK: state
    fileprivate static var container: [StateRoutine.ID: StateRoutine] = [:]
    fileprivate static func register(_ object: StateRoutine) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: StateRoutine.ID) {
        container[id] = nil
    }
}
