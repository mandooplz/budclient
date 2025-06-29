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
    public func signIn() async {
        // capture
        guard self.id.isValid else { return }
        guard let idToken else { issue = KnownIssue(Error.idTokenIsNil); return }
        guard let accessToken else { issue = KnownIssue(Error.accessTokenIsNil); return }
        
        let authBoardRef = AuthBoardManager.get(self.authBoard)!
        let budClientRef = BudClientManager.get(authBoardRef.budClient)!
        let budServerLink = budClientRef.budServerLink!
        
        // compute
        let userId: String
        do {
            // register
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
            userId = try await accountHubLink.getUserId(idToken: idToken, accessToken: accessToken)
        } catch {
            self.issue = UnknownIssue(error)
            return
        }
        
        // mutate
        guard budClientRef.isUserSignedIn == false else { return }
        
        let projectBoardRef = ProjectBoard(userId: userId)
        let profileBoardRef = ProfileBoard(budClient: budClientRef.id,
                                           userId: userId,
                                           mode: self.mode)
        
        budClientRef.projectBoard = projectBoardRef.id
        budClientRef.profileBoard = profileBoardRef.id
        budClientRef.authBoard = nil
        budClientRef.isUserSignedIn = true
        
        authBoardRef.emailForm = nil
        authBoardRef.delete()
        self.delete()
        // EmailForm, SignUpForm에서처럼 전체 시스템 객체의 상태를 변화시킨다.
    }
    
    
    // MARK: value
    public struct ID: Sendable, Hashable {
        public let value: UUID
        
        
        @MainActor internal var isValid: Bool {
            GoogleFormManager.get(self) != nil
        }
    }
    public enum Error: String, Swift.Error {
        case idTokenIsNil, accessTokenIsNil
    }
}


// MARK: Object Manager
@MainActor
public final class GoogleFormManager: Sendable {
    // MARK: state
    private static var container: [GoogleForm.ID: GoogleForm] = [:]
    internal static func register(_ object: GoogleForm) {
        container[object.id] = object
    }
    internal static func unregister(_ id: GoogleForm.ID) {
        container[id] = nil
    }
    public static func get(_ id: GoogleForm.ID) -> GoogleForm? {
        container[id]
    }
}
