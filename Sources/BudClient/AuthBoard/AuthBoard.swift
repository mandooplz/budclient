//
//  AuthBoard.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation
import Tools


// MARK: Object
@MainActor @Observable
public final class AuthBoard {
    // MARK: core
    public init(budClient: BudClient.ID,
                mode: SystemMode) {
        self.id = ID(value: UUID())
        self.budClient = budClient
        self.mode = mode
        
        AuthBoardManager.register(self)
    }
    
    
    // MARK: state
    public nonisolated let id: ID
    public nonisolated let budClient: BudClient.ID
    private nonisolated let mode: SystemMode
    
    public internal(set) var currentUser: UserID?
    public var isUserSignedIn: Bool { currentUser != nil }
    
    public internal(set) var emailForm: EmailForm.ID?
    public var isSetUpRequired: Bool { emailForm == nil }
    
    public internal(set) var issue: (any Issuable)?
    public var isIssueOccurred: Bool { self.issue != nil }
    
    
    // MARK: action
    public func setUpEmailForm() {
        // mutate
        guard self.isSetUpRequired else { return }
        let emailFormRef = EmailForm(authBoard: self.id,
                                     mode: self.mode)
        self.emailForm = emailFormRef.id
    }
    
    // 추후에 Profile 객체에서 이를 
    public func signOut() {
        // capture
        guard isUserSignedIn else {
            self.issue = KnownIssue(Error.userIsNotSignedIn)
            return
        }
        let budClientRef = BudClientManager.get(self.budClient)!
        let projectBoard = budClientRef.projectBoard!
        let projectBoardRef = ProjectBoardManager.get(projectBoard)!
        
        // mutate
        self.currentUser = nil
        let emailFormRef = EmailForm(authBoard: self.id,
                                     mode: self.mode)
        self.emailForm = emailFormRef.id
        
        budClientRef.projectBoard = nil
        projectBoardRef.delete()
    }
    
    
    // MARK: value
    public struct ID: Sendable, Hashable {
        public let value: UUID
    }
    public typealias UserID = String
    public enum Error: String, Swift.Error {
        case userIsNotSignedIn
    }
}


// MARK: Object Manager
@MainActor
public final class AuthBoardManager {
    // MARK: state
    private static var container: [AuthBoard.ID: AuthBoard] = [:]
    public static func register(_ object: AuthBoard) {
        container[object.id] = object
    }
    public static func get(_ id: AuthBoard.ID) -> AuthBoard? {
        container[id]
    }
}
