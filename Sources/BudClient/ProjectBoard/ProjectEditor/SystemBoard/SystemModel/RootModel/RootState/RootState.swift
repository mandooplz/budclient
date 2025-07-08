//
//  RootState.swift
//  BudClient
//
//  Created by 김민우 on 7/9/25.
//
import Foundation
import Values
import BudServer


// MARK: Object
@MainActor @Observable
public final class RootState: Sendable {
    // MARK: core
    init(target: StateID) {
        self.target = target
        
        RootStateManager.register(self)
    }
    func delete() {
        RootStateManager.unregister(self.id)
    }
    
    
    // MARK: state
    nonisolated let id = ID()
    nonisolated let target: StateID
    
    
    // MARK: action
    
    
    // MARK: value
    @MainActor
    public struct ID: Sendable, Hashable {
        let value: UUID
        nonisolated init(value: UUID = UUID()) {
            self.value = value
        }
        
        var isExist: Bool {
            false
        }
        public var ref: RootState? {
            nil
        }
    }
}



// MARK: ObjectManager
@MainActor @Observable
fileprivate final class RootStateManager: Sendable {
    // MARK: state
    fileprivate static var container: [RootState.ID: RootState] = [:]
    fileprivate static func register(_ object: RootState) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: RootState.ID) {
        container[id] = nil
    }
}
