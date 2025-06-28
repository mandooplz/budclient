//
//  SignUpForm.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation
import Tools
import BudServer
import BudCache


// MARK: Object
@MainActor @Observable
public final class SignUpForm: Sendable {
    // MARK: core
    internal init(emailForm: EmailForm.ID,
                mode: SystemMode) {
        self.id = ID(value: UUID())
        self.emailForm = emailForm
        self.mode = mode
        
        SignUpFormManager.register(self)
    }
    internal func delete() {
        SignUpFormManager.unregister(self.id)
    }
    
    
    // MARK: state
    public nonisolated let id: ID
    public nonisolated let emailForm: EmailForm.ID
    private nonisolated let mode: SystemMode
    
    public var email: String?
    public var password: String?
    public var passwordCheck: String?
    
    public internal(set) var issue: (any Issuable)?
    public var isIssueOccurred: Bool { self.issue != nil }
    
    public internal(set) var isConsumed: Bool = false
    
    
    // MARK: action
    public func signUp() async {
        // capture
        guard let email else { issue = KnownIssue(Error.emailIsNil); return }
        guard let password else { issue = KnownIssue(Error.passwordIsNil); return}
        guard let passwordCheck else {
            issue = KnownIssue(Error.passwordCheckIsNil); return
        }
        if password != passwordCheck { issue = KnownIssue(Error.passwordsDoNotMatch); return }
        let emailFormRef = EmailFormManager.get(self.emailForm)!
        let authBoardRef = AuthBoardManager.get(emailFormRef.authBoard)!
        let budClientRef = BudClientManager.get(authBoardRef.budClient)!
        let budServerLink = budClientRef.budServerLink!
        let budCacheLink = budClientRef.budCacheLink
        
        // compute
        let userId: AuthBoard.UserID
        do {
            let accountHubLink = budServerLink.getAccountHub()
            
            let newTicket = AccountHubLink.Ticket()
            try await accountHubLink.insertTicket(newTicket)
            try await accountHubLink.generateForms()
            
            guard let registerFormLink = try await accountHubLink.getRegisterForm(newTicket) else {
                throw UnknownIssue(reason: "AccountHubLink.generateForms() failed")
            }
            try await registerFormLink.setEmail(email)
            try await registerFormLink.setPassword(password)
            
            try await registerFormLink.submit()
            try await registerFormLink.remove()
            
            // getUserId
            userId = try await accountHubLink.getUserId(email: email,
                                                        password: password)
            
            // setEmailCredential in BudCache
            try await budCacheLink.setEmailCredential(.init(email: email,
                                                            password: password))
        } catch {
            self.issue = UnknownIssue(error)
            return
        }
        
        
        // mutate
        let projectBoardRef = ProjectBoard(userId: userId)
        let profileBoardRef = ProfileBoard(budClient: budClientRef.id,
                                           userId: userId,
                                           mode: self.mode)
        
        budClientRef.authBoard = nil
        budClientRef.projectBoard = projectBoardRef.id
        budClientRef.profileBoard = profileBoardRef.id
        budClientRef.isUserSignedIn = true
        
        self.isConsumed = true
        self.delete()
        emailFormRef.delete()
        emailFormRef.signUpForm = nil
        authBoardRef.delete()
        authBoardRef.emailForm = nil
    }
    public func remove() {
        // mutate
        let emailFormRef = EmailFormManager.get(emailForm)
        emailFormRef?.signUpForm = nil
        self.delete()
    }
    
    
    // MARK: value
    public struct ID: Sendable, Hashable {
        public let value: UUID
    }
    public enum Error: String, Swift.Error {
        case budClientIsNotSetUp
        case emailIsNil, passwordIsNil, passwordCheckIsNil
        case passwordsDoNotMatch
    }
}

// MARK: Object Manager
@MainActor
public final class SignUpFormManager: Sendable {
    // MARK: state
    private static var container: [SignUpForm.ID: SignUpForm] = [:]
    public static func register(_ object: SignUpForm) {
        container[object.id] = object
    }
    public static func unregister(_ id: SignUpForm.ID) {
        container[id] = nil
    }
    public static func get(_ id: SignUpForm.ID) -> SignUpForm? {
        container[id]
    }
}
