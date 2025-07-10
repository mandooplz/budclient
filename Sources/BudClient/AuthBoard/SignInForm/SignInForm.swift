//
//  SignInForm.swift
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
public final class SignInForm: Debuggable {
    // MARK: core
    init(tempConfig: TempConfig<AuthBoard.ID>) {
        self.tempConfig = tempConfig
        
        EmailFormManager.register(self)
    }
    func delete() {
        EmailFormManager.unregister(self.id)
    }
    
    
    // MARK: state
    public nonisolated let id = ID()
    public nonisolated let tempConfig: TempConfig<AuthBoard.ID>

    public var email: String = ""
    public var password: String = ""
    
    public internal(set) var signUpForm: SignUpForm.ID?
    
    public var issue: (any Issuable)?
    
    
    // MARK: action
    public func signInByCache() async {
        await signInByCache(captureHook: nil,
                            mutateHook: nil)
    }
    func signInByCache(captureHook: Hook?, mutateHook: Hook?) async {
        // capture
        await captureHook?()
        guard id.isExist else { setIssue(Error.signInFormIsDeleted); return }
        let authBoardRef = self.tempConfig.parent.ref!
        let budClientRef = authBoardRef.tempConfig.parent.ref!
        
        // compute
        async let result: UserID? = {
            guard let budCacheRef = await tempConfig.budCache.ref else {
                return nil
            }
            return await budCacheRef.getUser()
        }()
        guard let user = await result else {
            setIssue(Error.userIsNilInCache); return
        }
        
        // mutate
        await mutateHook?()
        mutateForSignIn(budClientRef: budClientRef,
                        authBoardRef: authBoardRef,
                        user: user)
        
    }
    
    public func signIn() async {
        await self.signIn(captureHook: nil, mutateHook: nil)
    }
    func signIn(captureHook: Hook?, mutateHook: Hook?) async {
        // capture
        await captureHook?()
        guard id.isExist else { setIssue(Error.signInFormIsDeleted); return }
        guard email.isEmpty == false else { setIssue(Error.emailIsNil); return }
        guard password.isEmpty == false else { setIssue(Error.passwordIsNil); return }
        
        let authBoardRef = self.tempConfig.parent.ref!
        let budClientRef = authBoardRef.tempConfig.parent.ref!
        let tempConfig = authBoardRef.tempConfig
        
        // compute
        let user: UserID
        do {
            guard let budServerRef = await tempConfig.budServer.ref,
                    let accountHubRef = await budServerRef.accountHub.ref,
                    let budCacheRef = await tempConfig.budCache.ref else { return }
            
            async let userFromServer = try await accountHubRef.getUser(email: email,
                                                                       password: password)
            user = try await userFromServer
            
            await budCacheRef.setUser(user)
        } catch(let error as AccountHubError) {
            switch error {
            case .userNotFound: setIssue(Error.userNotFound)
            case .wrongPassword: setIssue(Error.wrongPassword)
            }
            return
        } catch {
            setUnknownIssue(error); return
        }
        
        // mutate
        await mutateHook?()
        mutateForSignIn(budClientRef: budClientRef,
                        authBoardRef: authBoardRef,
                        user: user)
    }
    private func mutateForSignIn(budClientRef: BudClient,
                                 authBoardRef: AuthBoard,
                                 user: UserID) {
        guard id.isExist else { setIssue(Error.signInFormIsDeleted); return  }
        guard budClientRef.isUserSignedIn == false else { return }
        let googleForm = authBoardRef.googleForm
        
        let config = tempConfig.getConfig(budClientRef.id, user: user)
        let projectBoardRef = ProjectBoard(config: config)
        let profileBoardRef = ProfileBoard(config: config)
        let communityRef = Community(config: config)
        
        budClientRef.projectBoard = projectBoardRef.id
        budClientRef.profileBoard = profileBoardRef.id
        budClientRef.community = communityRef.id
        budClientRef.authBoard = nil
        budClientRef.user = user
        
        authBoardRef.signInForm = nil
        authBoardRef.delete()
        signUpForm?.ref?.delete()
        googleForm?.ref?.delete()
        self.delete()
    }
    
    public func setUpSignUpForm() async {
        await setUpSignUpForm(mutateHook: nil)
    }
    func setUpSignUpForm(mutateHook: Hook?) async {
        // mutate
        await mutateHook?()
        guard id.isExist else { setIssue(Error.signInFormIsDeleted); return }
        guard signUpForm == nil else { return }
        
        let myConfig = tempConfig.setParent(self.id)
        
        let signUpFormRef = SignUpForm(tempConfig: myConfig)
        self.signUpForm = signUpFormRef.id
    }
    
    
    
    // MARK: value
    @MainActor
    public struct ID: Sendable, Hashable {
        public let value: UUID
        nonisolated init(value: UUID = UUID()) {
            self.value = value
        }
        
        internal var isExist: Bool {
            EmailFormManager.container[self] != nil
        }
        public var ref: SignInForm? {
            EmailFormManager.container[self]
        }
    }
    public enum Error: String, Swift.Error {
        case signInFormIsDeleted
        case emailIsNil, passwordIsNil
        case userNotFound, wrongPassword
        case userIsNilInCache
    }
}


// MARK: Object Manager
@MainActor @Observable
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
