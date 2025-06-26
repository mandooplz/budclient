//
//  EmailForm.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation
import Tools
import BudServer


// MARK: Object
@MainActor @Observable
public final class EmailForm: Sendable {
    // MARK: core
    public init(authBoard: AuthBoard.ID,
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
    
    public var email: String?
    public var password: String?
    
    public internal(set) var signUpForm: SignUpForm.ID?
    
    public internal(set) var issue: Issue?
    public var isIssueOccurred: Bool { self.issue != nil }
    
    
    // MARK: action
    public func setUpSignUpForm() {
        // mutate
        if self.signUpForm != nil { return }
        let registerFormRef = SignUpForm(emailForm: self.id, mode: self.mode)
        self.signUpForm = registerFormRef.id
    }
    public func signIn() async {
        // capture
        guard let email else { issue = Issue(isKnown: true, reason: Error.emailIsNil); return }
        guard let password else { issue = Issue(isKnown: true, reason: Error.passwordIsNil); return}
        let authBoardRef = AuthBoardManager.get(self.authBoard)!
        let budClientRef = BudClientManager.get(authBoardRef.budClient)!
        let budServerLink = budClientRef.budServerLink!
        
        // compute
        let userId: String
        do {

            let accountHubLink = budServerLink.getAccountHub()
            
            userId = try await accountHubLink.getUserId(email: email,
                                               password: password)
        } catch(let error as AccountHubLink.Error) {
            switch error {
            case .userNotFound: issue = Issue(isKnown: true, reason: Error.userNotFound)
            case .wrongPassword: issue = Issue(isKnown: true, reason: Error.wrongPassword)
            }
            return
        } catch {
            issue = Issue(isKnown: false, reason: error.localizedDescription)
            return
        }
        
        // mutate
        let projectBoardRef = ProjectBoard(userId: userId)
        budClientRef.projectBoard = projectBoardRef.id
        
        authBoardRef.currentUser = userId
        authBoardRef.emailForm = nil
        self.delete()
    }
    
    
    
    // MARK: value
    public struct ID: Sendable, Hashable {
        public let value: UUID
    }
    public enum Error: String, Swift.Error {
        case emailIsNil, passwordIsNil
        case userNotFound, wrongPassword
    }
}


// MARK: Object Manager
@MainActor
public final class EmailFormManager: Sendable {
    // MARK: state
    private static var container: [EmailForm.ID: EmailForm] = [:]
    public static func register(_ object: EmailForm) {
        container[object.id] = object
    }
    public static func unregister(_ id: EmailForm.ID) {
        container[id] = nil
    }
    public static func get(_ id: EmailForm.ID) -> EmailForm? {
        container[id]
    }
}
