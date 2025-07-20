//
//  FlowModel.swift
//  BudClient
//
//  Created by 김민우 on 7/4/25.
//
import Foundation
import Values


// Flow는 소프트웨어가 제공하는 하나의 기능을 의미할 수 있다.
// MARK: Object
@MainActor @Observable
public final class FlowModel: Sendable {
    // MARK: core
    init(config: Config<SystemModel.ID>) {
        self.config = config
        
        FlowModelManager.register(self)
    }
    func delete() {
        FlowModelManager.unregister(self.id)
    }
    
    // MARK: state
    nonisolated let id = ID()
    nonisolated let config: Config<SystemModel.ID>
    
    
    // MARK: action
    
    
    // MARK: value
    @MainActor
    public struct ID: Sendable, Hashable {
        let value: UUID
        nonisolated init(value: UUID = UUID()) {
            self.value = value
        }
        
        var isExist: Bool {
            FlowModelManager.container[self] != nil
        }
        public var ref: FlowModel? {
            FlowModelManager.container[self]
        }
    }
}

// MARK: Flow Manager
@MainActor @Observable
fileprivate final class FlowModelManager: Sendable {
    fileprivate static var container: [FlowModel.ID: FlowModel] = [:]
    fileprivate static func register(_ object: FlowModel) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: FlowModel.ID) {
        container[id] = nil
    }
}
