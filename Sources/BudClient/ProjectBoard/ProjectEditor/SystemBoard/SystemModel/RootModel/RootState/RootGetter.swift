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
    init(name: String,
         config: Config<RootState.ID>,
         target: GetterID) {
        self.config = config
        self.target = target
        
        self.name = name
        self.nameInput = name
        
        RootGetterManager.register(self)
    }
    func delete() {
        RootGetterManager.unregister(self.id)
    }
    
    
    // MARK: state
    nonisolated let id = ID()
    nonisolated let config: Config<RootState.ID>
    nonisolated let target: GetterID
    
    public internal(set) var name: String
    public var nameInput: String
    
    
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
