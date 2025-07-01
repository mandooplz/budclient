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
public final class SignUpForm: Debuggable {
    // MARK: core
    internal init(tempConfig: TempConfig<SignInForm.ID>) {
        self.id = ID(value: UUID())
        self.tempConfig = tempConfig
        
        SignUpFormManager.register(self)
    }
    internal func delete() {
        SignUpFormManager.unregister(self.id)
    }
    
    
    // MARK: state
    public nonisolated let id: ID
    public nonisolated let tempConfig: TempConfig<SignInForm.ID>
    
    public var email: String?
    public var password: String?
    public var passwordCheck: String?
    
    public var issue: (any Issuable)?
    
    
    // MARK: action
    public func signUp() async {
        await signUp(captureHook: nil, mutateHook: nil)
    }
    internal func signUp(captureHook: Hook?, mutateHook: Hook?) async {
        // capture
        await captureHook?()
        guard id.isExist else { setIssue(Error.signUpFormIsDeleted); return }
        guard let email else { setIssue(Error.emailIsNil); return }
        guard let password else { setIssue(Error.passwordIsNil); return}
        guard let passwordCheck else { setIssue(Error.passwordCheckIsNil); return }
        if password != passwordCheck { setIssue(Error.passwordsDoNotMatch); return }
        
        let signInFormRef = self.tempConfig.parent.ref!
        let authBoardRef = signInFormRef.tempConfig.parent.ref!
        let budClientRef = authBoardRef.tempConfig.parent.ref!
        let googleFormRef = authBoardRef.googleForm!.ref!

        
        // compute
        let user: UserID
        do {
            async let result = {
                let accountHubLink = tempConfig.budServerLink.getAccountHub()
                
                let newTicket = AccountHubLink.Ticket()
                await accountHubLink.insertEmailTicket(newTicket)
                await accountHubLink.updateEmailForms()
                
                guard let emailRegisterFormLink = await accountHubLink.getEmailRegisterForm(newTicket) else {
                    throw UnknownIssue(reason: "AccountHubLink.updateEmailForms() failed")
                }
                await emailRegisterFormLink.setEmail(email)
                await emailRegisterFormLink.setPassword(password)
                
                await emailRegisterFormLink.submit()
                await emailRegisterFormLink.remove()
                
                // getUserId
                return try await accountHubLink.getUserId(email: email,
                                                          password: password)
            }()
            
            user = try await result
            
            // setUserId
            await tempConfig.budCacheLink.setUser(user)
        } catch {
            setUnknownIssue(error)
            return
        }
        
        // compute
        let config = tempConfig.getConfig(budClientRef.id, user: user)
        
        
        // mutate
        await mutateHook?()
        guard id.isExist else { setIssue(Error.signUpFormIsDeleted); return }
        let projectBoardRef = ProjectBoard(config: config)
        let profileBoardRef = ProfileBoard(config: config)
        let communityRef = Community(config: config)
        
        budClientRef.authBoard = nil
        budClientRef.projectBoard = projectBoardRef.id
        budClientRef.profileBoard = profileBoardRef.id
        budClientRef.community = communityRef.id
        budClientRef.user = user
        

        self.delete()
        googleFormRef.delete()
        signInFormRef.delete()
        signInFormRef.signUpForm = nil
        authBoardRef.delete()
        authBoardRef.signInForm = nil
    }
    
    public func remove() async {
        await remove(mutateHook: nil)
    }
    internal func remove(mutateHook: Hook?) async {
        // mutate
        await mutateHook?()
        guard id.isExist else { setIssue(Error.signUpFormIsDeleted); return }
        
        let signInForm = tempConfig.parent
        signInForm.ref?.signUpForm = nil
        
        self.delete()
    }
    
    
    // MARK: value
    @MainActor
    public struct ID: Sendable, Hashable {
        public let value: UUID
        
        internal var isExist: Bool {
            SignUpFormManager.container[self] != nil
        }
        public var ref: SignUpForm? {
            SignUpFormManager.container[self]
        }
    }
    public enum Error: String, Swift.Error {
        case signUpFormIsDeleted
        case budClientIsNotSetUp
        case emailIsNil, passwordIsNil, passwordCheckIsNil
        case passwordsDoNotMatch
    }
}

// MARK: Object Manager
@MainActor @Observable
fileprivate final class SignUpFormManager: Sendable {
    // MARK: state
    fileprivate static var container: [SignUpForm.ID: SignUpForm] = [:]
    fileprivate static func register(_ object: SignUpForm) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: SignUpForm.ID) {
        container[id] = nil
    }
}
