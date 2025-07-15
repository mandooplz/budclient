//
//  ObjectBoard.swift
//  BudClient
//
//  Created by 김민우 on 7/16/25.
//
import Foundation
import Values


// MARK: Object
@MainActor @Observable
public final class ObjectBoard: Sendable {
    // MARK: core
    
    
    // MARK: state
    nonisolated let id = ID()
    
    
    // MARK: action
    
    
    // MARK: value
    @MainActor
    public struct ID: Sendable, Hashable {
        public let value = UUID()
        nonisolated init() { }
        
        public var isExist: Bool {
            fatalError()
        }
        public var ref: ObjectBoard? {
            fatalError()
        }
    }
}



// MARK: ObjectManager
@MainActor @Observable
fileprivate final class ObjectBoardManager: Sendable {
    // MARK: state
    fileprivate static var container: [ObjectBoard.ID: ObjectBoard] = [:]
    fileprivate static func register(_ object: ObjectBoard) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: ObjectBoard.ID) {
        container[id] = nil
    }
}
