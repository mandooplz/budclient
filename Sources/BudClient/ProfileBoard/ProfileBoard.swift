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
    internal init(mode: SystemMode, budClient: BudClient.ID, userId: String) {
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
        let projectBoard = budClient.ref!.projectBoard
        let community = budClient.ref!.community
        
        // compute
        
        
        // mutate
        let budClientRef = self.budClient.ref!
        let projectBoardRef = projectBoard!.ref!
        let communityRef = community!.ref!
        let authBoardRef = AuthBoard(budClient: self.budClient,
                                     mode: self.mode)
        budClientRef.authBoard = authBoardRef.id
        budClientRef.projectBoard = nil
        budClientRef.profileBoard = nil
        
        projectBoardRef.delete()
        communityRef.delete()
        self.delete()
    }


    // MARK: value
    @MainActor public struct ID: Sendable, Hashable {
        public let value: UUID
        
        internal var isExist: Bool {
            ProfileBoardManager.container[self] != nil
        }
        public var ref: ProfileBoard? {
            ProfileBoardManager.container[self]
        }
    }
}


// MARK: Object Manager
@MainActor
fileprivate final class ProfileBoardManager: Sendable {
    // MARK: state
    fileprivate static var container: [ProfileBoard.ID: ProfileBoard] = [:]
    fileprivate static func register(_ object: ProfileBoard) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: ProfileBoard.ID) {
        container[id] = nil
    }
}
