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
public final class ObjectGetter: Sendable {
    // MARK: core
    init(target: GetterID) {
        self.target = target
        
        ObjectGetterManager.register(self)
    }
    func delete() {
        ObjectGetterManager.unregister(self.id)
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
            ObjectGetterManager.container[self] != nil
        }
        public var ref: ObjectGetter? {
            ObjectGetterManager.container[self]
        }
    }
}


// MARK: Object Manager
@MainActor @Observable
fileprivate final class ObjectGetterManager: Sendable {
    // MARK: state
    fileprivate static var container: [ObjectGetter.ID: ObjectGetter] = [:]
    fileprivate static func register(_ object: ObjectGetter) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: ObjectGetter.ID) {
        container[id] = nil
    }
}
