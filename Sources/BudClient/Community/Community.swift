//
//  Community.swift
//  BudClient
//
//  Created by 김민우 on 6/29/25.
//
import Foundation
import Values


// MARK: Object
@MainActor @Observable
public final class Community: Debuggable {
    // MARK: core
    init(config: Config<BudClient.ID>) {
        self.config = config
        
        CommunityManager.register(self)
    }
    func delete() {
        CommunityManager.unregister(self.id)
    }
    
    
    // MARK: state
    public nonisolated let id = ID()
    public nonisolated let config: Config<BudClient.ID>
    
    public var issue: (any Issuable)?
    
    
    
    // MARK: action
    
    
    
    // MARK: value
    @MainActor
    public struct ID: Sendable, Hashable {
        public let value: UUID
        nonisolated init(value: UUID = UUID()) {
            self.value = value
        }
        
        var isExist: Bool {
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
