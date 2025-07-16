//
//  ActionModel.swift
//  BudClient
//
//  Created by 김민우 on 7/7/25.
//
import Foundation
import Values

private let logger = WorkFlow.getLogger(for: "ActionModel")


// MARK: Object
@MainActor @Observable
public final class ActionModel: Sendable {
    // MARK: core
    init(target: ActionID) {
        self.target = target
        
        ActionModelManager.register(self)
    }
    func delete() {
        ActionModelManager.unregister(self.id)
    }
    
    
    // MARK: state
    nonisolated let id = ID()
    nonisolated let target: ActionID
    
    public var name: String?
    
    
    // MARK: action
    public func remove() { }
    
    
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
