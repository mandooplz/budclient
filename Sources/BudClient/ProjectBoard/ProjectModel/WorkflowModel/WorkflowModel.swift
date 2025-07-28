//
//  WorkflowModel.swift
//  BudClient
//
//  Created by 김민우 on 7/16/25.
//
import Foundation
import Values
import BudServer


// MARK: Object
@MainActor @Observable
public final class WorkflowModel: Sendable {
    // MARK: core
    init(config: Config<ProjectModel.ID>,
         diff: WorkflowSourceDiff) {
        self.config = config
        self.target = diff.target
        
        self.createdAt = diff.createdAt
        self.updatedAt = diff.updatedAt
        self.order = diff.order
        
        WorkflowModelManager.register(self)
    }
    func delete() {
        WorkflowModelManager.unregister(self.id)
    }
    
    
    // MARK: state
    nonisolated let id = ID()
    nonisolated let config: Config<ProjectModel.ID>
    nonisolated let target: WorkflowID
    
    nonisolated let createdAt: Date
    var updatedAt: Date
    var order: Int
    
    
    // MARK: action
    
    
    // MARK: value
    @MainActor
    public struct ID: Sendable, Hashable {
        public let value = UUID()
        nonisolated init() { }
        
        public var isExist: Bool {
            WorkflowModelManager.container[self] != nil
        }
        public var ref: WorkflowModel? {
            WorkflowModelManager.container[self]
        }
    }
}



// MARK: ObjectManager
@MainActor @Observable
fileprivate final class WorkflowModelManager: Sendable {
    // MARK: state
    fileprivate static var container: [WorkflowModel.ID: WorkflowModel] = [:]
    fileprivate static func register(_ object: WorkflowModel) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: WorkflowModel.ID) {
        container[id] = nil
    }
}
