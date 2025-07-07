//
//  FlowBoard.swift
//  BudClient
//
//  Created by 김민우 on 7/7/25.
//
import Foundation
import Values


// MARK: Object
@MainActor @Observable
public final class FlowBoard: Sendable {
    // MARK: core
    init() {
        FlowBoardManager.register(self)
    }
    func delete() {
        FlowBoardManager.unregister(self.id)
    }
    
    
    // MARK: state
    nonisolated let id = ID()
    
    
    // MARK: action
    
    
    // MARK: value
    @MainActor
    public struct ID: Sendable, Hashable {
        let value: UUID
        nonisolated init(value: UUID = UUID()) {
            self.value = value
        }
        
        var isExist: Bool {
            FlowBoardManager.container[self] != nil
        }
        public var ref: FlowBoard? {
            FlowBoardManager.container[self]
        }
    }
}



// MARK: Object Manager
@MainActor @Observable
fileprivate final class FlowBoardManager: Sendable {
    fileprivate static var container: [FlowBoard.ID: FlowBoard] = [:]
    fileprivate static func register(_ object: FlowBoard) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: FlowBoard.ID) {
        container[id] = nil
    }
}
