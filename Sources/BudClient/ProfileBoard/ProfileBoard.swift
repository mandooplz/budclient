//
//  ProfileBoard.swift
//  BudClient
//
//  Created by 김민우 on 6/26/25.
//
import Foundation
import Tools
import BudServer


// MARK: Object
@MainActor @Observable
public final class ProfileBoard: Sendable {
    // MARK: core
    internal init(budClient: BudClient.ID,
                  userId: String,
                  mode: SystemMode) {
        self.id = ID(value: UUID())
        self.userId = userId
        self.budClient = budClient
        self.mode = mode

        ProfileBoardManager.register(self)
    }
    internal func delete() {
        ProfileBoardManager.unregister(self.id)
    }

    // MARK: state
    public nonisolated let id: ID
    private nonisolated let mode: SystemMode
    public nonisolated let userId: String
    public nonisolated let budClient: BudClient.ID
    
    public internal(set) var issue: (any Issuable)?
    
    
    // MARK: action
    public func signOut() {
        // capture
        let budClientRef = BudClientManager.get(self.budClient)!
        let projectBoard = budClientRef.projectBoard!
        let projectBoardRef = ProjectBoardManager.get(projectBoard)!
        
        // mutate
        let authBoardRef = AuthBoard(budClient: self.budClient,
                                     mode: self.mode)
        budClientRef.authBoard = authBoardRef.id
        budClientRef.projectBoard = nil
        budClientRef.profileBoard = nil
        
        projectBoardRef.delete()
        self.delete()
    }


    // MARK: value
    public struct ID: Sendable, Hashable {
        public let value: UUID
    }
}


// MARK: Object Manager
@MainActor
public final class ProfileBoardManager: Sendable {
    // MARK: state
    private static var container: [ProfileBoard.ID: ProfileBoard] = [:]
    public static func register(_ object: ProfileBoard) {
        container[object.id] = object
    }
    public static func unregister(_ id: ProfileBoard.ID) {
        container[id] = nil
    }
    public static func get(_ id: ProfileBoard.ID) -> ProfileBoard? {
        container[id]
    }
}
