//
//  SetterModel.swift
//  BudClient
//
//  Created by 김민우 on 7/7/25.
//
import Foundation
import Values


// MARK: Object
@MainActor @Observable
public final class ObjectSetter: Sendable {
    // MARK:  Core
    init(target: StateID) {
        self.target = target
        
        ObjectSetterManager.register(self)
    }
    func delete() {
        ObjectSetterManager.unregister(self.id)
    }
    
    
    
    // MARK: state
    nonisolated let id = ID()
    nonisolated let target: StateID

    
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
            ObjectSetterManager.container[self] != nil
        }
        public var ref: ObjectSetter? {
            ObjectSetterManager.container[self]
        }
    }
}


// MARK: Object Manager
@MainActor @Observable
fileprivate final class ObjectSetterManager: Sendable {
    // MARK: state
    fileprivate static var container: [ObjectSetter.ID: ObjectSetter] = [:]
    fileprivate static func register(_ object: ObjectSetter) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: ObjectSetter.ID) {
        container[id] = nil
    }
}
