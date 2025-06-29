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
    internal init(emailForm: SignInForm.ID,
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
    public nonisolated let emailForm: SignInForm.ID
    private nonisolated let mode: SystemMode
    
    public var email: String?
    public var password: String?
    public var passwordCheck: String?
    
    public internal(set) var issue: (any Issuable)?
    public var isIssueOccurred: Bool { self.issue != nil }
    
    public internal(set) var isConsumed: Bool = false
    
    
    // MARK: action
    public func signUp() async {
        await signUp(captureHook: nil, mutateHook: nil)
    }
    internal func signUp(captureHook: Hook?, mutateHook: Hook?) async {
        // capture
        await captureHook?()
        guard id.isExist else { return }
        guard let email else { issue = KnownIssue(Error.emailIsNil); return }
        guard let password else { issue = KnownIssue(Error.passwordIsNil); return}
        guard let passwordCheck else {
            issue = KnownIssue(Error.passwordCheckIsNil); return
        }
        if password != passwordCheck { issue = KnownIssue(Error.passwordsDoNotMatch); return }
        let emailFormRef = self.emailForm.ref!
        let authBoardRef = emailFormRef.authBoard.ref!
        let budClientRef = authBoardRef.budClient.ref!
        let googleFormRef = authBoardRef.googleForm!.ref!
        
        let budServerLink = budClientRef.budServerLink!
        let budCacheLink = budClientRef.budCacheLink
        
        // compute
        let userId: AuthBoard.UserID
        do {
            let accountHubLink = budServerLink.getAccountHub()
            
            let newTicket = AccountHubLink.Ticket()
            await accountHubLink.insertEmailTicket(newTicket)
            await accountHubLink.updateEmailForms()
            
            guard let registerFormLink = await accountHubLink.getEmailRegisterForm(newTicket) else {
                throw UnknownIssue(reason: "AccountHubLink.updateEmailForms() failed")
            }
            await registerFormLink.setEmail(email)
            await registerFormLink.setPassword(password)
            
            await registerFormLink.submit()
            await registerFormLink.remove()
            
            // getUserId
            userId = try await accountHubLink.getUserId(email: email,
                                                        password: password)
            
            // setEmailCredential in BudCache
            await budCacheLink.setUserId(userId)
        } catch {
            self.issue = UnknownIssue(error)
            return
        }
        
        
        // mutate
        await mutateHook?()
        guard id.isExist else { return }
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
        googleFormRef.delete()
        emailFormRef.delete()
        emailFormRef.signUpForm = nil
        authBoardRef.delete()
        authBoardRef.signInForm = nil
    }
    
    public func remove() async {
        await remove(mutateHook: nil)
    }
    internal func remove(mutateHook: Hook?) async {
        // mutate
        await mutateHook?()
        guard id.isExist else { return }
        emailForm.ref?.signUpForm = nil
        self.delete()
    }
    
    
    // MARK: value
    @MainActor
    public struct ID: Sendable, Hashable {
        public let value: UUID
        
        internal var isExist: Bool {
            SignUpFormManager.get(self) != nil
        }
        public var ref: SignUpForm? {
            SignUpFormManager.get(self)
        }
    }
    public enum Error: String, Swift.Error {
        case budClientIsNotSetUp
        case emailIsNil, passwordIsNil, passwordCheckIsNil
        case passwordsDoNotMatch
    }
}

// MARK: Object Manager
@MainActor
fileprivate final class SignUpFormManager: Sendable {
    // MARK: state
    private static var container: [SignUpForm.ID: SignUpForm] = [:]
    fileprivate static func register(_ object: SignUpForm) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: SignUpForm.ID) {
        container[id] = nil
    }
    fileprivate static func get(_ id: SignUpForm.ID) -> SignUpForm? {
        container[id]
    }
}
