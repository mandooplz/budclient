//
//  SignInForm.swift
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
public final class SignInForm: Sendable {
    // MARK: core
    internal init(authBoard: AuthBoard.ID,
                  mode: SystemMode) {
        self.id = ID(value: UUID())
        self.authBoard = authBoard
        self.mode = mode
        
        EmailFormManager.register(self)
    }
    internal func delete() {
        EmailFormManager.unregister(self.id)
    }
    
    
    // MARK: state
    public nonisolated let id: ID
    public nonisolated let authBoard: AuthBoard.ID
    private nonisolated let mode: SystemMode

    public var email: String = ""
    public var password: String = ""
    
    public internal(set) var signUpForm: SignUpForm.ID?
    public var isSetUpRequired: Bool { signUpForm == nil }
    
    public var issue: (any Issuable)?
    public var isIssueOccurred: Bool { self.issue != nil }
    
    internal var issueForDebug: (any Issuable)?
    
    
    // MARK: action
    public func signInByCache() async {
        await signInByCache(captureHook: nil,
                            mutateHook: nil)
    }
    internal func signInByCache(captureHook: Hook?, mutateHook: Hook?) async {
        // capture
        await captureHook?()
        guard id.isExist else { issueForDebug = KnownIssue(Error.deleted); return }
        let authBoardRef = self.authBoard.ref!
        let budClientRef = authBoardRef.budClient.ref!
        let budCacheLink = budClientRef.budCacheLink
        
        // compute
        guard let userId = await budCacheLink.getUserId() else {
            issueForDebug = KnownIssue(Error.userIdIsNilInCache)
            return
        }
        
        // mutate
        await mutateHook?()
        mutateForSignIn(budClientRef: budClientRef,
                        authBoardRef: authBoardRef,
                        userId: userId)
        
    }
    
    public func signIn() async {
        await self.signIn(captureHook: nil, mutateHook: nil)
    }
    internal func signIn(captureHook: Hook?, mutateHook: Hook?) async {
        // capture
        await captureHook?()
        guard id.isExist else { issueForDebug = KnownIssue(Error.deleted); return }
        guard email != "" else {
            self.issue = KnownIssue(Error.emailIsNil)
            return
        }
        guard password != "" else {
            self.issue = KnownIssue(Error.passwordIsNil)
            return
        }
        
        let authBoardRef = self.authBoard.ref!
        let budClientRef = authBoardRef.budClient.ref!
        let budServerLink = budClientRef.budServerLink!
        let budCacheLink = budClientRef.budCacheLink
        
        // compute
        let userId: String
        do {
            let accountHubLink = budServerLink.getAccountHub()
            
            userId = try await accountHubLink.getUserId(email: email,
                                                        password: password)
            
            await budCacheLink.setUserId(userId)
        } catch(let error as AccountHubLink.Error) {
            switch error {
            case .userNotFound: issue = KnownIssue(Error.userNotFound)
            case .wrongPassword: issue = KnownIssue(Error.wrongPassword)
            }
            return
        } catch {
            self.issue = UnknownIssue(error)
            return
        }
        
        // mutate
        await mutateHook?()
        mutateForSignIn(budClientRef: budClientRef,
                        authBoardRef: authBoardRef,
                        userId: userId)
    }
    private func mutateForSignIn(budClientRef: BudClient,
                                 authBoardRef: AuthBoard,
                                 userId: String) {
        guard id.isExist else { issueForDebug = KnownIssue(Error.deleted); return  }
        guard budClientRef.isUserSignedIn == false else { return }
        let googleForm = authBoardRef.googleForm
        
        let projectBoardRef = ProjectBoard(userId: userId)
        let profileBoardRef = ProfileBoard(budClient: budClientRef.id,
                                           userId: userId,
                                           mode: self.mode)
        
        budClientRef.projectBoard = projectBoardRef.id
        budClientRef.profileBoard = profileBoardRef.id
        budClientRef.authBoard = nil
        budClientRef.isUserSignedIn = true
        
        authBoardRef.signInForm = nil
        authBoardRef.delete()
        signUpForm?.ref?.delete()
        googleForm?.ref?.delete()
        self.delete()
    }
    
    public func setUpSignUpForm() async {
        await setUpSignUpForm(mutateHook: nil)
    }
    internal func setUpSignUpForm(mutateHook: Hook?) async {
        // mutate
        await mutateHook?()
        guard id.isExist else { return }
        guard isSetUpRequired else { return }
        
        let signUpFormRef = SignUpForm(emailForm: self.id, mode: self.mode)
        self.signUpForm = signUpFormRef.id
    }
    
    
    
    // MARK: value
    @MainActor
    public struct ID: Sendable, Hashable {
        public let value: UUID
        
        internal var isExist: Bool {
            EmailFormManager.container[self] != nil
        }
        public var ref: SignInForm? {
            EmailFormManager.container[self]
        }
    }
    public enum Error: String, Swift.Error {
        case deleted
        case emailIsNil, passwordIsNil
        case userNotFound, wrongPassword
        case missingEmailCredentialInCache
        case userIdIsNilInCache
    }
}


// MARK: Object Manager
@MainActor
fileprivate final class EmailFormManager: Sendable {
    // MARK: state
    fileprivate static var container: [SignInForm.ID: SignInForm] = [:]
    fileprivate static func register(_ object: SignInForm) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: SignInForm.ID) {
        container[id] = nil
    }
}
