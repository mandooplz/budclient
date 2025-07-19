//
//  GoogleForm.swift
//  BudClient
//
//  Created by 김민우 on 6/28/25.
//
import Foundation
import Values
import BudCache
import BudServer

private let logger = BudLogger("GoogleForm")


// MARK: Object
@MainActor @Observable
public final class GoogleForm: Debuggable, Hookable {
    // MARK: core
    init(tempConfig: TempConfig<SignInForm.ID>) {
        self.tempConfig = tempConfig
        
        GoogleFormManager.register(self)
    }
    func delete() {
        GoogleFormManager.unregister(self.id)
    }
    
    
    // MARK: state
    public nonisolated let id = ID()
    public nonisolated let tempConfig: TempConfig<SignInForm.ID>
    
    public private(set) var googleClientId: String?
    
    public var idToken: String?
    public var accessToken: String?
    
    public var issue: (any IssueRepresentable)?
    
    package var captureHook: Hook? = nil
    package var computeHook: Hook? = nil
    package var mutateHook: Hook? = nil
    
    
    // MARK: action
    public func fetchGoogleClientId() async {
        logger.start()
        
        // capture
        await captureHook?()
        guard id.isExist else {
            setIssue(Error.googleFormIsDeleted)
            logger.failure("GoogleForm이 존재하지 않아 실행취소 됩니다.")
            return
        }
        let tempConfig = self.tempConfig
        
        // compute
        await computeHook?()
        async let googleClientId: String? = {
            guard let budServerRef = await tempConfig.budServer.ref,
                  let accountHubRef = await budServerRef.accountHub.ref else { return nil }
            
            let budClientInfoFormRef = await accountHubRef.budClientInfoFormType.init()
            await budClientInfoFormRef.fetchGoogleClientId()
            let result = await budClientInfoFormRef.googleClientId
            
            return result
        }()
        
        // mutate
        await mutateHook?()
        self.googleClientId = await googleClientId
    }
    public func submit() async {
        logger.start()
        
        // capture
        await captureHook?()
        guard self.id.isExist else {
            setIssue(Error.googleFormIsDeleted)
            logger.failure("GoogleForm이 존재하지 않아 실행 취소됩니다.")
            return
        }
        guard let idToken else {
            issue = KnownIssue(Error.idTokenIsNil)
            logger.failure("GoogleForm의 idToken이 존재하지 않습니다.")
            return
        }
        guard let accessToken else {
            issue = KnownIssue(Error.accessTokenIsNil)
            logger.failure("GoogleForm accessToken이 존재하지 않습니다.")
            return
        }
        
        let config = tempConfig
        let signInForm = config.parent
        let budClientRef = config.parent.ref!.tempConfig.parent.ref!
        let googleToken = GoogleToken(idToken: idToken,
                                      accessToken: accessToken)
        
        // compute - register
        await computeHook?()
        guard let budServerRef = await tempConfig.budServer.ref,
              let accountHubRef = await budServerRef.accountHub.ref else { return }
        
        await withDiscardingTaskGroup { group in
            group.addTask {
                let googleRegisterFormRef = await accountHubRef.googleRegisterFormType
                    .init(token: googleToken)
                
                await googleRegisterFormRef.submit()
            }
        }
        
        
        // compute - signIn
        async let signInResult = {
            let googleAuthFormRef = await accountHubRef.googleAuthFormType
                .init(token: googleToken)
            
            await googleAuthFormRef.submit()
            
            return await googleAuthFormRef.result
        }()

        
        
        guard let result = await signInResult else {
            logger.failure("GoogleAuthForm에서 result가 생성되지 않았습니다.")
            return
        }
        
        // mutate
        await mutateHook?()
        guard id.isExist else {
            setIssue(Error.googleFormIsDeleted)
            logger.failure("GoogleForm이 존재하지 않아 실행 취소됩니다.")
            return
        }
        switch result {
        case .success(let user):
            mutateForSignIn(budClientRef, signInForm, user, config)
        case .failure(let error):
            setUnknownIssue(error)
        }
    }
    private func mutateForSignIn(_ budClientRef: BudClient,
                                 _ signInForm: SignInForm.ID,
                                 _ user: UserID,
                                 _ tempConfig: TempConfig<SignInForm.ID>) {
        // compute
        let newConfig = tempConfig.getConfig(budClientRef.id,
                                         user: user)
        
        // mutate
        signInForm.ref?.signUpForm?.ref?.delete()
        signInForm.ref?.delete()
         
        let projectBoardRef = ProjectBoard(config: newConfig)
        let profileBoardRef = Profile(config: newConfig)
        let communityRef = Community(config: newConfig)
        
        budClientRef.signInForm = nil
        budClientRef.projectBoard = projectBoardRef.id
        budClientRef.profile = profileBoardRef.id
        budClientRef.community = communityRef.id
        
        budClientRef.user = user
        
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
            GoogleFormManager.container[self] != nil
        }
        public var ref: GoogleForm? {
            GoogleFormManager.container[self]
        }
    }
    public enum Error: String, Swift.Error {
        case idTokenIsNil, accessTokenIsNil
        case googleFormIsDeleted
    }
}


// MARK: Object Manager
@MainActor @Observable
fileprivate final class GoogleFormManager: Sendable {
    // MARK: state
    fileprivate static var container: [GoogleForm.ID: GoogleForm] = [:]
    fileprivate static func register(_ object: GoogleForm) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: GoogleForm.ID) {
        container[id] = nil
    }
}
