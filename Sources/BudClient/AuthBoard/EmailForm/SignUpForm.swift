//
//  SignUpForm.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation
import Tools
import BudServer


// MARK: Object
@MainActor
public final class SignUpForm: Sendable {
    // MARK: core
    public init(emailForm: EmailForm.ID,
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
    
    public var issue: Issue?
    public var isConsumed: Bool = false
    
    
    // MARK: action
    public func signUp() async {
        // capture
        guard let email else { issue = Issue(isKnown: true,
                                             reason: Error.emailIsNil); return }
        guard let password else { issue = Issue(isKnown: true,
                                                reason: Error.passwordIsNil); return}
        if password != passwordCheck { issue = Issue(isKnown: true,
                                                     reason: Error.passwordsDoNotMatch); return }
        let emailFormRef = EmailFormManager.get(self.emailForm)!
        let authBoardRef = AuthBoardManager.get(emailFormRef.authBoard)!
        
        // compute
        let userId: AuthBoard.UserID?
        do {
            // register
            let budServerLink = BudServerLink(mode: self.mode)
            let accountHubLink = budServerLink.getAccountHub()
            
            let newTicket = AccountHubLink.Ticket()
            try await accountHubLink.insertTicket(newTicket)
            try await accountHubLink.generateForms()
            
            guard let registerFormLink = try await accountHubLink.getRegisterForm(newTicket) else {
                throw Issue(isKnown: false, reason: "registerFormDoesNotExist")
            }
            try await registerFormLink.setEmail(email)
            try await registerFormLink.setPassword(password)
            try await registerFormLink.submit()
            try await registerFormLink.remove()
            
            // getUserId
            userId = try await accountHubLink.getUserId(email: email,
                                                        password: password)
        } catch {
            self.issue = Issue(isKnown: false,
                               reason: error.localizedDescription)
            return
        }
        
        
        // mutate
        authBoardRef.currentUser = userId
        authBoardRef.emailForm = nil
        emailFormRef.delete()
        self.isConsumed = true
        self.delete()
    }
    
    
    // MARK: value
    public struct ID: Sendable, Hashable {
        public let value: UUID
    }
    public enum Error: String, Swift.Error {
        case emailIsNil, passwordIsNil
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
