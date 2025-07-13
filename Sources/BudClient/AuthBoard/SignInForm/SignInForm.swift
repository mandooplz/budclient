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

private let logger = WorkFlow.getLogger(for: "SignInForm")


// MARK: Object
@MainActor @Observable
public final class SignInForm: Debuggable {
    // MARK: core
    init(tempConfig: TempConfig<AuthBoard.ID>) {
        self.tempConfig = tempConfig
        
        SignInFormManager.register(self)
    }
    func delete() {
        SignInFormManager.unregister(self.id)
    }
    
    
    // MARK: state
    public nonisolated let id = ID()
    public nonisolated let tempConfig: TempConfig<AuthBoard.ID>

    public var email: String = ""
    public var password: String = ""
    
    public internal(set) var signUpForm: SignUpForm.ID?
    public internal(set) var googleForm: GoogleForm.ID?
    
    public var issue: (any Issuable)?
    
    
    // MARK: action
    public func signInByCache() async {
        logger.start()
        
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
            setIssue(Error.userIsNilInCache)
            logger.failure(Error.userIsNilInCache)
            return
        }
        
        // mutate
        await mutateHook?()
        mutateForSignIn(budClientRef: budClientRef,
                        authBoardRef: authBoardRef,
                        user: user)
        
    }
    
    public func signIn() async {
        logger.start()
        
        await self.signIn(captureHook: nil, mutateHook: nil)
    }
    func signIn(captureHook: Hook?, mutateHook: Hook?) async {
        // capture
        await captureHook?()
        guard id.isExist else { setIssue(Error.signInFormIsDeleted); return }
        guard email.isEmpty == false else {
            setIssue(Error.emailIsEmpty)
            logger.failure(Error.emailIsEmpty)
            return
        }
        guard password.isEmpty == false else {
            setIssue(Error.passwordIsEmpty)
            logger.failure(Error.passwordIsEmpty)
            return
        }
        
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
        } catch {
            logger.failure(error)
            
            if error is AccountHubError {
                switch error as! AccountHubError {
                case .userNotFound: setIssue(Error.userNotFound)
                case .wrongPassword: setIssue(Error.wrongPassword)
                }
            } else {
                setUnknownIssue(error)
            }
            
            return
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
        self.googleForm?.ref?.delete()
        self.delete()
    }
    
    public func setUpSignUpForm() async {
        logger.start()
        
        await setUpSignUpForm(mutateHook: nil)
    }
    func setUpSignUpForm(mutateHook: Hook?) async {
        // mutate
        await mutateHook?()
        guard id.isExist else { setIssue(Error.signInFormIsDeleted); return }
        guard signUpForm == nil else {
            logger.failure(Error.signUpFormAlreadyExist)
            return
        }
        
        let myConfig = tempConfig.setParent(self.id)
        
        let signUpFormRef = SignUpForm(tempConfig: myConfig)
        self.signUpForm = signUpFormRef.id
    }
    
    public func setUpGoogleForm() async {
        logger.start()
        
        await setUpGoogleForm(mutateHook: nil)
    }
    func setUpGoogleForm(mutateHook: Hook?) async {
        // capture
        let signInForm = self.id
        let config = self.tempConfig
        
        // mutate
        await mutateHook?()
        guard id.isExist else { setIssue(Error.signInFormIsDeleted); return }
        let googleFormRef = GoogleForm(tempConfig: config.setParent(signInForm))
        
        self.googleForm = googleFormRef.id
    }
    
    
    
    // MARK: value
    @MainActor
    public struct ID: Sendable, Hashable {
        public let value: UUID
        nonisolated init(value: UUID = UUID()) {
            self.value = value
        }
        
        internal var isExist: Bool {
            SignInFormManager.container[self] != nil
        }
        public var ref: SignInForm? {
            SignInFormManager.container[self]
        }
    }
    public enum Error: String, Swift.Error {
        case signInFormIsDeleted
        case signUpFormAlreadyExist
        case emailIsEmpty, passwordIsEmpty
        case userNotFound, wrongPassword
        case userIsNilInCache
    }
}


// MARK: Object Manager
@MainActor @Observable
fileprivate final class SignInFormManager: Sendable {
    // MARK: state
    fileprivate static var container: [SignInForm.ID: SignInForm] = [:]
    fileprivate static func register(_ object: SignInForm) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: SignInForm.ID) {
        container[id] = nil
    }
}
