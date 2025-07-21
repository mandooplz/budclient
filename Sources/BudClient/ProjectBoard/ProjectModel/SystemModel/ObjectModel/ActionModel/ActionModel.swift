//
//  ActionModel.swift
//  BudClient
//
//  Created by 김민우 on 7/7/25.
//
import Foundation
import Values
import BudServer

private let logger = BudLogger("ActionModel")


// MARK: Object
@MainActor @Observable
public final class ActionModel: Sendable {
    // MARK: core
    init(config: Config<ObjectModel.ID>,
         diff: ActionSourceDiff) {
        self.config = config
        self.target = diff.target
        
        self.name = diff.name
        self.nameInput = diff.name
        
        ActionModelManager.register(self)
    }
    func delete() {
        ActionModelManager.unregister(self.id)
    }
    
    
    // MARK: state
    nonisolated let id = ID()
    nonisolated let config: Config<ObjectModel.ID>
    nonisolated let target: ActionID
    
    public internal(set) var name: String
    public var nameInput: String
    
    
    // MARK: action
    public func removeAction() {
        fatalError()
    }
    
    
    // MARK: value
    @MainActor
    public struct ID: Sendable, Hashable {
        let value: UUID
        nonisolated init(value: UUID = UUID()) {
            self.value = value
        }
        
        var isExist: Bool {
            ActionModelManager.container[self] != nil
        }
        public var ref: ActionModel? {
            ActionModelManager.container[self]
        }
    }
}


// MARK: Object Manager
@MainActor @Observable
fileprivate final class ActionModelManager: Sendable {
    // MARK: state
    fileprivate static var container: [ActionModel.ID: ActionModel] = [:]
    fileprivate static func register(_ object: ActionModel) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: ActionModel.ID) {
        container[id] = nil
    }
}
