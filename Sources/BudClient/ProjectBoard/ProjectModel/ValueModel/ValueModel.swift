//
//  ValueModel.swift
//  BudClient
//
//  Created by 김민우 on 7/16/25.
//
import Foundation
import Values
import BudServer


// MARK: Object
@MainActor @Observable
public final class ValueModel: Sendable {
    // MARK: core
    init(config: Config<ProjectModel.ID>) {
        self.config = config
        
        ValueModelManager.register(self)
    }
    func delete() {
        ValueModelManager.unregister(self.id)
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
            ValueModelManager.container[self] != nil
        }
        public var ref: ValueModel? {
            ValueModelManager.container[self]
        }
    }
}



// MARK: ObjectManager
@MainActor @Observable
fileprivate final class ValueModelManager: Sendable {
    // MARK: state
    fileprivate static var container: [ValueModel.ID: ValueModel] = [:]
    fileprivate static func register(_ object: ValueModel) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: ValueModel.ID) {
        container[id] = nil
    }
}

