//
//  RootModel.swift
//  BudClient
//
//  Created by 김민우 on 7/9/25.
//
import Foundation
import Values
import BudServer


// MARK: Object
@MainActor @Observable
public final class RootModel: Sendable {
    // MARK: core
    init(config: Config<SystemModel.ID>) {
        self.config = config
        
        RootModelManager.register(self)
    }
    func delete() {
        RootModelManager.unregister(self.id)
    }
    
    
    // MARK: state
    nonisolated let id = ID()
    nonisolated let config: Config<SystemModel.ID>
    
    public var name: String?
    
    
    
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
        public var ref: RootModel? {
            nil
        }
    }
}


// MARK: ObjectManager
@MainActor @Observable
fileprivate final class RootModelManager: Sendable {
    // MARK: state
    fileprivate static var container: [RootModel.ID: RootModel] = [:]
    fileprivate static func register(_ object: RootModel) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: RootModel.ID) {
        container[id] = nil
    }
}
