//
//  BudClient.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation


// MARK: Object
@MainActor
public final class BudClient: Sendable {
    // MARK: core
    public init() {
        self.id = ID(value: UUID())
        
        BudClientManager.register(self)
    }
    internal func delete() {
        BudClientManager.unregister(self.id)
    }
    
    
    // MARK: state
    public nonisolated let id: ID
    
    public var authBoard: AuthBoard.ID?
    
    
    // MARK: action
    public func setUp() {
        // mutate
        if self.authBoard != nil { return }
        let authBoardRef = AuthBoard()
        self.authBoard = authBoardRef.id
    }
    
    
    // MARK: value
    public struct ID: Sendable, Hashable {
        public let value: UUID
    }
}


// MARK: Object Manager
@MainActor
public final class BudClientManager: Sendable {
    // MARK: state
    private static var container: [BudClient.ID: BudClient] = [:]
    public static func register(_ object: BudClient) {
        container[object.id] = object
    }
    public static func unregister(_ id: BudClient.ID) {
        container[id] = nil
    }
    public static func get(_ id: BudClient.ID) -> BudClient? {
        container[id]
    }
}
