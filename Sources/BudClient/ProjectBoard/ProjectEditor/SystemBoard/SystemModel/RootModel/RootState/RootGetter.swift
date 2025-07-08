//
//  RootGetter.swift
//  BudClient
//
//  Created by 김민우 on 7/9/25.
//
import Foundation
import Values
import BudServer


// MARK: Object
@MainActor @Observable
public final class RootGetter: Sendable {
    // MARK: core
    init(target: GetterID) {
        self.target = target
        
        RootGetterManager.register(self)
    }
    func delete() {
        RootGetterManager.unregister(self.id)
    }
    
    
    // MARK: state
    nonisolated let id = ID()
    nonisolated let target: GetterID
    
    
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
        public var ref: RootGetter? {
            nil
        }
    }
}



// MARK: ObjectManager
@MainActor @Observable
fileprivate final class RootGetterManager: Sendable {
    // MARK: state
    fileprivate static var container: [RootGetter.ID: RootGetter] = [:]
    fileprivate static func register(_ object: RootGetter) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: RootGetter.ID) {
        container[id] = nil
    }
}
