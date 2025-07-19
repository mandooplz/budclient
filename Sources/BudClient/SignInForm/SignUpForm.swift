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

private let logger = BudLogger("SignUpForm")

// MARK: Object
@MainActor @Observable
public final class SignUpForm: Debuggable, Hookable {
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
    
    public var email: String = ""
    public var password: String = ""
    public var passwordCheck: String = ""
    
    public var issue: (any IssueRepresentable)?
    
    package var captureHook: Hook? = nil
    package var computeHook: Hook? = nil
    package var mutateHook: Hook? = nil
    
    
    // MARK: action
    public func submit() async {
        logger.start()
        
        // capture
        await captureHook?()
        guard id.isExist else {
            setIssue(Error.signUpFormIsDeleted)
            logger.failure("SignUpForm이 존재하지 않아 실행취소됩니다.")
            return
        }
        guard email.isEmpty == false else {
            setIssue(Error.emailIsEmpty)
            logger.failure("SignUpForm의 Email이 빈 문자열입니다.")
            return
        }
        guard password.isEmpty == false else {
            setIssue(Error.passwordIsEmpty)
            logger.failure("SignUpForm의 Password가 빈 문자열입니다.")
            return
        }
        guard passwordCheck.isEmpty == false else {
            setIssue(Error.passsworCheckIsEmpty)
            logger.failure("SignUpForm의 passwordCheck가 빈 문자열입니다.")
            return
        }
        guard password == passwordCheck else {
            setIssue(Error.passwordsDoNotMatch)
            logger.failure("SignUpForm의 Password와 PasswordCheck가 일치하지 않습니다.")
            return
        }
        
        let config = self.tempConfig
        let signInFormRef = config.parent.ref!
        let budClientRef = config.parent.ref!
            .tempConfig.parent.ref!

        
        // compute - register
        await computeHook?()
        async let budServerRef = await config.budServer.ref!
        let accountHubRef = await budServerRef.accountHub.ref!
        
        let emailRegisterFormRef = await accountHubRef.emailRegisterFormType
            .init(email: email, password: password)
        
        await emailRegisterFormRef.submit()
        
        // compute - signIn
        let emailAuthFormRef = await accountHubRef.emailAuthFormType.init(email: email, password: password)
        await emailAuthFormRef.submit()
        
        guard let result = await emailAuthFormRef.result else {
            logger.failure("EmaiLAuthForm에서 result가 생성되지 않았습니다.")
            return
        }
        
        
        // mutate
        await mutateHook?()
        switch result {
        case .failure(let error):
            setUnknownIssue(error)
        case .success(let user):
            // mutate
            guard id.isExist else { setIssue(Error.signUpFormIsDeleted)
                logger.failure("SignUpForm이 존재하지 않아 실행 취소됩니다.")
                return
            }
            let newConfig = config.getConfig(budClientRef.id, user: user)
            
            let projectBoardRef = ProjectBoard(config: newConfig)
            let profileBoardRef = Profile(config: newConfig)
            let communityRef = Community(config: newConfig)
            
            budClientRef.signInForm = nil
            budClientRef.projectBoard = projectBoardRef.id
            budClientRef.profile = profileBoardRef.id
            budClientRef.community = communityRef.id
            
            budClientRef.user = user

            self.delete()
            signInFormRef.delete()
            signInFormRef.signUpForm = nil
            signInFormRef.googleForm?.ref?.delete()
        }

        
        
    }
    public func cancel() async {
        logger.start()
        
        // capture
        await captureHook?()
        guard id.isExist else { setIssue(Error.signUpFormIsDeleted); return }
        
        let signInForm = self.tempConfig.parent
        
        // mutate
        await mutateHook?()
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
        case emailIsEmpty, passwordIsEmpty, passsworCheckIsEmpty
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
