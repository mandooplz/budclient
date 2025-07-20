//
//  StateModel.swift
//  BudClient
//
//  Created by 김민우 on 7/7/25.
//
import Foundation
import Values
import BudServer

private let logger = BudLogger("StateModel")


// MARK: Object
@MainActor @Observable
public final class StateModel: Sendable {
    // MARK: core
    init(config: Config<ObjectModel.ID>,
         diff: StateSourceDiff) {
        self.target = diff.target
        self.updater = Updater(owner: self.id)
        self.source = diff.id
        
        self.name = diff.name
        self.nameInput = diff.name
        
        StateModelManager.register(self)
    }
    func delete() {
        StateModelManager.unregister(self.id)
    }
    
    
    // MARK: state
    nonisolated let id = ID()
    nonisolated let target: StateID
    nonisolated let updater: Updater
    nonisolated let source: any StateSourceIdentity
    
    public internal(set) var name: String
    public var nameInput: String
    
    public var accessLevel : AccessLevel = .readAndWrite
    public var stateValue: StateValue = .AnyValue
    
    public internal(set) var getters: [GetterModel.ID] = []
    public internal(set) var setters: [SetterModel.ID] = []
    
    
    // MARK: action
    public func pushName() async {
        logger.start()
        
        await self.pushName(captureHook: nil)
    }
    func pushName(captureHook: Hook?) async {
        // capture
        await captureHook?()
        guard id.isExist else {
            return
        }
    }
    
    public func createGetter() async {
        logger.start()
        
        await self.createGetter(captureHook: nil)
    }
    func createGetter(captureHook: Hook?) async {
        
    }
    
    public func createSetter() async {
        logger.start()
        
        await self.createSetter(captureHook: nil)
    }
    func createSetter(captureHook: Hook?) async {
        // capture
    }
    
    public func duplicate() async { }
    
    public func removeState() async {
        
    }
    
    
    // MARK: value
    @MainActor
    public struct ID: Sendable, Hashable {
        public let value: UUID
        nonisolated init(value: UUID = UUID()) {
            self.value = value
        }
        
        public var isExist: Bool {
            StateModelManager.container[self] != nil
        }
        public var ref: StateModel? {
            StateModelManager.container[self]
        }
    }
}


// MARK: Objec Manager
@MainActor @Observable
fileprivate final class StateModelManager: Sendable {
    // MARK: state
    fileprivate static var container: [StateModel.ID: StateModel] = [:]
    fileprivate static func register(_ object: StateModel) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: StateModel.ID) {
        container[id] = nil
    }
}
