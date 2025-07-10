//
//  SignUpForm.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation
import Values
import BudServer
import BudCache


// MARK: Object
@MainActor @Observable
public final class SignUpForm: Debuggable {
    // MARK: core
    init(tempConfig: TempConfig<SignInForm.ID>) {
        self.tempConfig = tempConfig
        
        SignUpFormManager.register(self)
    }
    func delete() {
        SignUpFormManager.unregister(self.id)
    }
    
    
    // MARK: state
    public nonisolated let id = ID()
    public nonisolated let tempConfig: TempConfig<SignInForm.ID>
    
    public var email: String?
    public var password: String?
    public var passwordCheck: String?
    
    public var issue: (any Issuable)?
    
    
    // MARK: action
    public func signUp() async {
        await signUp(captureHook: nil, mutateHook: nil)
    }
    func signUp(captureHook: Hook?, mutateHook: Hook?) async {
        // capture
        await captureHook?()
        guard id.isExist else { setIssue(Error.signUpFormIsDeleted); return }
        guard let email else { setIssue(Error.emailIsNil); return }
        guard let password else { setIssue(Error.passwordIsNil); return }
        guard let passwordCheck else { setIssue(Error.passwordCheckIsNil); return }
        if password != passwordCheck { setIssue(Error.passwordsDoNotMatch); return }
        
        let signInFormRef = self.tempConfig.parent.ref!
        let authBoardRef = signInFormRef.tempConfig.parent.ref!
        let budClientRef = authBoardRef.tempConfig.parent.ref!
        let googleFormRef = authBoardRef.googleForm!.ref!
        let tempConfig = self.tempConfig

        
        // compute
        let user: UserID
        do {
            async let budServerRef = await tempConfig.budServer.ref!
            let accountHubRef = await budServerRef.accountHub.ref!
            async let budCacheRef = await tempConfig.budCache.ref!
            
            async let result = {
                let ticket = CreateFormTicket(formType: .email)
                
                await accountHubRef.appendTicket(ticket)
                await accountHubRef.createFormsFromTickets()
                
                guard let emailRegisterFormRef = await accountHubRef.getEmailRegisterForm(ticket: ticket)?.ref else {
                    throw UnknownIssue(reason: "AccountHubLink.updateEmailForms() failed")
                }
                await emailRegisterFormRef.setEmail(email)
                await emailRegisterFormRef.setPassword(password)
                
                try await emailRegisterFormRef.submit()
                try await emailRegisterFormRef.remove()
                
                // getUser
                return try await accountHubRef.getUser(email: email,
                                                        password: password)
            }()
            
            user = try await result
            
            // setUserId
            await budCacheRef.setUser(user)
        } catch {
            setUnknownIssue(error); return
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
        nonisolated init(value: UUID = UUID()) {
            self.value = value
        }
        
        var isExist: Bool {
            SignUpFormManager.container[self] != nil
        }
        public var ref: SignUpForm? {
            SignUpFormManager.container[self]
        }
    }
    public enum Error: String, Swift.Error {
        case signUpFormIsDeleted
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
