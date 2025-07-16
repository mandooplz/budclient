//
//  ObjectModel.swift
//  BudClient
//
//  Created by 김민우 on 7/4/25.
//
import Foundation
import Values


// MARK: Object
@MainActor @Observable
public final class ObjectModel: Sendable {
    // MARK: core
    init(name: String,
         role: ObjectRole,
         target: ObjectID,
         config: Config<SystemModel.ID>) {
        self.name = name
        self.role = role
        self.target = target
        self.config = config
        
        ObjectModelManager.register(self)
    }
    func delete() {
        ObjectModelManager.unregister(self.id)
    }
    
    
    // MARK: state
    nonisolated let id = ID()
    nonisolated let config: Config<SystemModel.ID>
    nonisolated let target: ObjectID
    
    public var name: String
    
    public var role: ObjectRole
    
    
    // MARK: action
    public func pushName() async { }
    func pushName(captureHook: Hook?) async { }
    
    public func appendChild() { }
    public func appendParent() { }
    
    public func createState() { }
    public func createAction() { }
    
    public func makeFlow() {
        // makeFlow는 어떤 액션인가.
    }
    
    public func remove() { }
    
    
    // MARK: value
    @MainActor
    public struct ID: Sendable, Hashable {
        public let value: UUID
        nonisolated init(value: UUID = UUID()) {
            self.value = value
        }
        
        var isExist: Bool {
            ObjectModelManager.container[self] != nil
        }
        var ref: ObjectModel? {
            ObjectModelManager.container[self]
        }
    }
}


// MARK: Object Manager
@MainActor @Observable
fileprivate final class ObjectModelManager: Sendable {
    fileprivate static var container: [ObjectModel.ID: ObjectModel] = [:]
    fileprivate static func register(_ object: ObjectModel) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: ObjectModel.ID) {
        container[id] = nil
    }
}
