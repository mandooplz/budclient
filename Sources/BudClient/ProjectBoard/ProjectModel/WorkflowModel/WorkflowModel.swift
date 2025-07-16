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
    init(config: Config<ProjectModel.ID>) {
        self.config = config
        
        WorkflowModelManager.register(self)
    }
    func delete() {
        WorkflowModelManager.unregister(self.id)
    }
    
    
    // MARK: state
    nonisolated let id = ID()
    nonisolated let config: Config<ProjectModel.ID>
    
    
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
