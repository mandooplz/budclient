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

private let logger = BudLogger("SignInForm")


// MARK: Object
@MainActor @Observable
public final class SignInForm: Debuggable {
    // MARK: core
    init(tempConfig: TempConfig<BudClient.ID>) {
        self.tempConfig = tempConfig
        
        SignInFormManager.register(self)
    }
    func delete() {
        SignInFormManager.unregister(self.id)
    }
    
    
    // MARK: state
    public nonisolated let id = ID()
    public nonisolated let tempConfig: TempConfig<BudClient.ID>

    public var email: String = ""
    public var password: String = ""
    
    public internal(set) var signUpForm: SignUpForm.ID?
    public internal(set) var googleForm: GoogleForm.ID?
    
    public var issue: (any IssueRepresentable)?
    
    
    // MARK: action
    public func signInByCache() async {
        logger.start()
        
        await signInByCache(captureHook: nil, mutateHook: nil)
    }
    func signInByCache(captureHook: Hook?, mutateHook: Hook?) async {
        // capture
        await captureHook?()
        guard id.isExist else { setIssue(Error.signInFormIsDeleted); return }
        let budClientRef = self.tempConfig.parent.ref!
        guard budClientRef.isUserSignedIn == false else {
            setIssue(Error.alreadySignedIn)
            logger.failure("이미 로그인된 상태입니다.")
            return
        }
        
        // compute
        async let result: UserID? = {
            let budCacheRef = await tempConfig.budCache.ref!
            
            return await budCacheRef.getUser()
        }()
        guard let user = await result else {
            setIssue(Error.userIsNilInCache)
            logger.failure("BudCache에 User 정보가 존재하지 않습니다.")
            return
        }
        
        // mutate
        await mutateHook?()
        guard id.isExist else {
            setIssue(Error.signInFormIsDeleted)
            logger.failure("SignInForm이 존재하지 않아 실행 취소됩니다.")
            return
        }
        mutateForSignIn(budClientRef: budClientRef, user: user)
    }
    
    public func signIn() async {
        logger.start()
        
        await self.signIn(captureHook: nil, mutateHook: nil)
    }
    func signIn(captureHook: Hook?, mutateHook: Hook?) async {
        // capture
        await captureHook?()
        guard id.isExist else { setIssue(Error.signInFormIsDeleted); return }
        let budClientRef = self.tempConfig.parent.ref!
        guard budClientRef.isUserSignedIn == false else {
            setIssue(Error.alreadySignedIn)
            logger.failure("이미 로그인된 상태입니다.")
            return
        }
        
        guard email.isEmpty == false else {
            setIssue(Error.emailIsEmpty)
            logger.failure("SignInForm의 email이 빈 문자열입니다.")
            return
        }
        guard password.isEmpty == false else {
            setIssue(Error.passwordIsEmpty)
            logger.failure("SignInForm의 password가 빈 문자열입니다.")
            return
        }
        
        let tempConfig = self.tempConfig
        let (email, password) = (self.email, self.password)
        
        // compute
        let budServerRef = await tempConfig.budServer.ref!
        let accountHubRef = await budServerRef.accountHub.ref!
        
        let emailAuthFormRef = await accountHubRef.emailAuthFormType
            .init(email: email, password: password)
        
        await emailAuthFormRef.submit()
        
        guard let result = await emailAuthFormRef.result else {
            logger.failure("EmailAuthForm에서 result가 생성되지 않았습니다.")
            return
        }
        
        
        // mutate
        await mutateHook?()
        guard id.isExist else {
            setIssue(Error.signInFormIsDeleted)
            logger.failure("SignInForm이 존재하지 않아 실행 취소됩니다.")
            return
        }
        switch result {
        case .success(let user):
            mutateForSignIn(budClientRef: budClientRef, user: user)
        case .failure(.userNotFound):
            setIssue(Error.userNotFound)
        case .failure(.wrongPassword):
            setIssue(Error.wrongPassword)
        case .failure(.unknown(let error)):
            setUnknownIssue(error)
        }
        
    }
    private func mutateForSignIn(budClientRef: BudClient, user: UserID) {
        
        
        let config = tempConfig.getConfig(budClientRef.id, user: user)
        let projectBoardRef = ProjectBoard(config: config)
        let profileBoardRef = Profile(config: config)
        let communityRef = Community(config: config)
        
        budClientRef.signInForm = nil
        budClientRef.projectBoard = projectBoardRef.id
        budClientRef.profileBoard = profileBoardRef.id
        budClientRef.community = communityRef.id
        
        budClientRef.user = user
        
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
        case alreadySignedIn
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
