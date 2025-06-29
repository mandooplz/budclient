//
//  Community.swift
//  BudClient
//
//  Created by 김민우 on 6/29/25.
//
import Foundation
import Tools


// MARK: Object
@MainActor @Observable
public final class Community: Sendable {
    // MARK: core
    public init(mode: SystemMode, budClient: BudClient.ID, userId: String) {
        self.id = ID(value: .init())
        self.mode = mode
        self.budCliet = budClient
        self.userId = userId
        
        CommunityManager.register(self)
    }
    internal func delete() {
        CommunityManager.unregister(self.id)
    }
    
    
    // MARK: state
    public nonisolated let id: ID
    internal nonisolated let mode: SystemMode
    public nonisolated let budCliet: BudClient.ID
    internal nonisolated let userId: String
    
    
    
    // MARK: action
    
    
    
    // MARK: value
    @MainActor
    public struct ID: Sendable, Hashable {
        public let value: UUID
        
        internal var isExist: Bool {
            CommunityManager.container[self] != nil
        }
        public var ref: Community? {
            CommunityManager.container[self]
        }
    }
}


// MARK: Object Manager
@MainActor @Observable
fileprivate final class CommunityManager: Sendable {
    // MARK: state
    fileprivate static var container: [Community.ID: Community] = [:]
    fileprivate static func register(_ object: Community) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: Community.ID) {
        container[id] = nil
    }
}
