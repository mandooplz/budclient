//
//  ObjectModel.swift
//  BudClient
//
//  Created by 김민우 on 7/4/25.
//
import Foundation
import Values
import BudServer

private let logger = BudLogger("ObjectModel")


// MARK: Object
@MainActor @Observable
public final class ObjectModel: Sendable, Debuggable {
    // MARK: core
    init(name: String,
         role: ObjectRole,
         target: ObjectID,
         config: Config<SystemModel.ID>,
         source: any ObjectSourceIdentity) {
        self.target = target
        self.source = source
        self.config = config
        self.updaterRef = Updater(owner: self.id)
        
        self.role = role
        self.name = name
        self.nameInput = name
        
        ObjectModelManager.register(self)
    }
    func delete() {
        ObjectModelManager.unregister(self.id)
    }
    
    
    // MARK: state
    nonisolated let id = ID()
    nonisolated let config: Config<SystemModel.ID>
    nonisolated let target: ObjectID
    nonisolated let updaterRef: Updater
    nonisolated let source: any ObjectSourceIdentity
    
    public nonisolated let role: ObjectRole
    public internal(set) var name: String
    public var nameInput: String
    
    public internal(set) var states: [StateModel.ID] = []
    public internal(set) var actions: [ActionModel.ID] = []
    
    public var issue: (any IssueRepresentable)?
    
    
    // MARK: action
    public func subscribeSource() { }
    public func unsubscribeSource() { }
    
    public func pushName() async { }
    func pushName(captureHook: Hook?) async { }
    
    public func addChildObject() { }
    public func addParentObject() { }
    
    public func createState() { }
    public func createAction() { }
    
    public func removeObject() { }
    
    
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
