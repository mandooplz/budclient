//
//  RootSetter.swift
//  BudClient
//
//  Created by 김민우 on 7/9/25.
//
import Foundation
import Values
import BudServer


// MARK: Object
@MainActor @Observable
public final class RootSetter: Sendable {
    // MARK: core
    init(target: SetterID) {
        self.target = target
        
        RootSetterManager.register(self)
    }
    func delete() {
        RootSetterManager.unregister(self.id)
    }
    
    
    // MARK: state
    nonisolated let id = ID()
    nonisolated let target: SetterID
    
    
    // MARK: action
    
    
    
    // MARK: value
    @MainActor
    public struct ID: Sendable, Hashable {
        let value: UUID
        nonisolated init(value: UUID = UUID()) {
            self.value = value
        }
    }
}



// MARK: ObjectManager
@MainActor @Observable
fileprivate final class RootSetterManager: Sendable {
    // MARK: state
    fileprivate static var container: [RootSetter.ID: RootSetter] = [:]
    fileprivate static func register(_ object: RootSetter) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: RootSetter.ID) {
        container[id] = nil
    }
}

