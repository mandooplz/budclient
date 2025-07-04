//
//  GoogleForm.swift
//  BudClient
//
//  Created by 김민우 on 6/28/25.
//
import Foundation
import Tools
import BudCache
import BudServer


// MARK: Object
@MainActor @Observable
public final class GoogleForm: Debuggable {
    // MARK: core
    init(tempConfig: TempConfig<AuthBoard.ID>) {
        self.tempConfig = tempConfig
        
        GoogleFormManager.register(self)
    }
    func delete() {
        GoogleFormManager.unregister(self.id)
    }
    
    
    // MARK: state
    public nonisolated let id = ID()
    public nonisolated let tempConfig: TempConfig<AuthBoard.ID>
    
    public var idToken: String?
    public var accessToken: String?
    
    public var issue: (any Issuable)?
    
    
    // MARK: action
    public func signUpAndSignIn() async {
        await signUpAndSignIn(captureHook: nil, mutateHook: nil)
    }
    func signUpAndSignIn(captureHook: Hook?, mutateHook: Hook?) async {
        // capture
        await captureHook?()
        guard self.id.isExist else { setIssue(Error.googleFormIsDeleted); return }
        guard let idToken else { issue = KnownIssue(Error.idTokenIsNil); return }
        guard let accessToken else { issue = KnownIssue(Error.accessTokenIsNil); return }
        
        let config = tempConfig
        let authBoardRef = config.parent.ref!
        let budClientRef = authBoardRef.tempConfig.parent.ref!
        
        // compute
        let user: UserID
        do {
            // register
            async let result = {
                let accountHubLink = await config.budServerLink.getAccountHub()
                let ticket = AccountHubLink.Ticket()
                
                await accountHubLink.insertGoogleTicket(ticket)
                await accountHubLink.updateGoogleForms()
                
                guard let googleRegisterFormLink = await accountHubLink.getGoogleRegisterForm(ticket) else {
                    throw UnknownIssue(reason: "GoogleRegisterFormLink.updateGoogleForms() failed")
                }
                
                let googleToken = GoogleToken(idToken: idToken, accessToken: accessToken)
                await googleRegisterFormLink.setToken(googleToken)
                
                await googleRegisterFormLink.submit()
                await googleRegisterFormLink.remove()
                
                // signIn
                return try await accountHubLink.getUser(token: googleToken)
            }()
            
            user = try await result
            
            // save in BudCache
            await config.budCacheLink.setUser(user)
        } catch {
            setUnknownIssue(error); return
        }
        
        // compute
        let newConfig = config.getConfig(budClientRef.id, user: user)
        
        // mutate
        await mutateHook?()
        guard id.isExist else { setIssue(Error.googleFormIsDeleted); return }
        
        authBoardRef.signInForm?.ref?.signUpForm?.ref?.delete()
        authBoardRef.signInForm?.ref?.delete()
         
        let projectBoardRef = ProjectBoard(config: newConfig)
        let profileBoardRef = ProfileBoard(config: newConfig)
        let communityRef = Community(config: newConfig)
        
        budClientRef.projectBoard = projectBoardRef.id
        budClientRef.profileBoard = profileBoardRef.id
        budClientRef.community = communityRef.id
        budClientRef.authBoard = nil
        budClientRef.user = user
        
        authBoardRef.signInForm = nil
        authBoardRef.delete()
        
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
