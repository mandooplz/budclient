//
//  ComponentBoard.swift
//  BudClient
//
//  Created by 김민우 on 7/16/25.
//
import Foundation
import Values


// MARK: Object
@MainActor @Observable
public final class ComponentBoard: Sendable {
    // MARK: core
    init(config: Config<ProjectEditor.ID>) {
        self.config = config
        
        ComponentBoardManager.register(self)
    }
    func delete() {
        ComponentBoardManager.unregister(self.id)
    }
    
    
    // MARK: state
    nonisolated let id = ID()
    nonisolated let config: Config<ProjectEditor.ID>
    
    
    
    
    // MARK: action
    
    
    
    // MARK: value
    @MainActor
    public struct ID: Sendable, Hashable {
        public let value = UUID()
        nonisolated init() { }
        
        public var isExist: Bool {
            ComponentBoardManager.container[self] != nil
        }
        public var ref: ComponentBoard? {
            ComponentBoardManager.container[self]
        }
    }
}


// MARK: ObjectManager
@MainActor @Observable
fileprivate final class ComponentBoardManager: Sendable {
    // MARK: state
    fileprivate static var container: [ComponentBoard.ID: ComponentBoard] = [:]
    fileprivate static func register(_ object: ComponentBoard) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: ComponentBoard.ID) {
        container[id] = nil
    }
}
