//
//  ValueBoard.swift
//  BudClient
//
//  Created by 김민우 on 7/9/25.
//
import Foundation
import Values


// MARK: Object
@MainActor @Observable
public final class ValueBoard: Sendable {
    // MARK: core
    init(config: Config<ProjectEditor.ID>) {
        self.config = config
        
        ValueBoardManager.register(self)
    }
    func delete() {
        ValueBoardManager.unregister(self.id)
    }
    
    
    // MARK: state
    nonisolated let id = ID()
    nonisolated let config: Config<ProjectEditor.ID>
    
    
    // MARK: action
    
    
    // MARK: value
    @MainActor
    public struct ID: Sendable, Hashable {
        let value: UUID
        nonisolated init(value: UUID = UUID()) {
            self.value = value
        }
        
        var isExist: Bool {
            ValueBoardManager.container[self] != nil
        }
        public var ref: ValueBoard? {
            ValueBoardManager.container[self]
        }
    }
}


// MARK: ObjectManager
@MainActor @Observable
fileprivate final class ValueBoardManager: Sendable {
    // MARK: state
    fileprivate static var container: [ValueBoard.ID: ValueBoard] = [:]
    fileprivate static func register(_ object: ValueBoard) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: ValueBoard.ID) {
        container[id] = nil
    }
}
