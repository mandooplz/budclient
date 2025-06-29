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
public final class GoogleForm: Sendable {
    // MARK: core
    internal init(authBoard: AuthBoard.ID,
                  mode: SystemMode) {
        self.id = ID(value: UUID())
        self.mode = mode
        self.authBoard = authBoard
        
        GoogleFormManager.register(self)
    }
    internal func delete() {
        GoogleFormManager.unregister(self.id)
    }
    
    
    // MARK: state
    public nonisolated let id: ID
    public nonisolated let authBoard: AuthBoard.ID
    internal nonisolated let mode: SystemMode
    
    public var idToken: String?
    public var accessToken: String?
    
    public var issue: (any Issuable)?
    
    
    // MARK: action
    public func signUpAndSignIn() async {
        await signUpAndSignIn(captureHook: nil, mutateHook: nil)
    }
    internal func signUpAndSignIn(captureHook: Hook?, mutateHook: Hook?) async {
        // capture
        await captureHook?()
        guard self.id.isExist else { return }
        guard let idToken else { issue = KnownIssue(Error.idTokenIsNil); return }
        guard let accessToken else { issue = KnownIssue(Error.accessTokenIsNil); return }
        
        let authBoardRef = authBoard.ref!
        let budClientRef = authBoardRef.budClient.ref!
        let budServerLink = budClientRef.budServerLink!
        let budCacheLink = budClientRef.budCacheLink
        
        // compute
        let userId: String
        do {
            // register
            async let result = {
                let accountHubLink = budServerLink.getAccountHub()
                let ticket = AccountHubLink.Ticket()
                
                await accountHubLink.insertGoogleTicket(ticket)
                await accountHubLink.updateGoogleForms()
                
                guard let googleRegisterFormLink = await accountHubLink.getGoogleRegisterForm(ticket) else {
                    throw UnknownIssue(reason: "GoogleRegisterFormLink.updateGoogleForms() failed")
                }
                
                await googleRegisterFormLink.setIdToken(idToken)
                await googleRegisterFormLink.setAccessToken(accessToken)
                
                await googleRegisterFormLink.submit()
                await googleRegisterFormLink.remove()
                
                // signIn
                return try await accountHubLink.getUserId(idToken: idToken, accessToken: accessToken)
            }()
            
            userId = try await result
            
            // save in BudCache
            await budCacheLink.setUserId(userId)
        } catch {
            self.issue = UnknownIssue(error)
            return
        }
        
        // mutate
        await mutateHook?()
        guard id.isExist else { return }
        
        authBoardRef.signInForm?.ref?.signUpForm?.ref?.delete()
        authBoardRef.signInForm?.ref?.delete()
         
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
        
        self.delete()
    }
    
    
    // MARK: value
    @MainActor
    public struct ID: Sendable, Hashable {
        public let value: UUID
        
        internal var isExist: Bool {
            GoogleFormManager.container[self] != nil
        }
        public var ref: GoogleForm? {
            GoogleFormManager.container[self]
        }
    }
    public enum Error: String, Swift.Error {
        case idTokenIsNil, accessTokenIsNil
    }
}


// MARK: Object Manager
@MainActor
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
