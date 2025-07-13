//
//  AccountHub.swift
//  BudClient
//
//  Created by 김민우 on 6/24/25.
//
import Foundation
import Values
import Collections
import FirebaseAuth
import FirebaseCore

private let logger = WorkFlow.getLogger(for: "AccountHub")


// MARK: Object
@MainActor
package final class AccountHub: AccountHubInterface {
    // MARK: core
    init() {
        AccountHubManager.register(self)
    }
    
    
    // MARK: state
    package nonisolated let id = ID()
    
    package func getGoogleClientID(for systemName: String) async -> String? {
        return FirebaseApp.app()?.options.clientID
    }
    
    package func isExist(email: String, password: String) async throws -> Bool {
        do {
            let _ = try await Auth.auth().signIn(withEmail: email, password: password)
        } catch let error as NSError {
            if let errorCode = AuthErrorCode(rawValue: error.code) {
                switch errorCode {
                case .userNotFound:
                    throw Error.userNotFound
                case .wrongPassword:
                    throw Error.wrongPassword
                default:
                    throw error
                }
            } else {
                throw error
            }
        }
        
        return true
    }
    package func getUser(email: String, password: String) async throws -> UserID {
        logger.start()
        
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            return UserID(result.user.uid)
        } catch let error as NSError {
            if let errorCode = AuthErrorCode(rawValue: error.code) {
                switch errorCode {
                case .userNotFound:
                    throw Error.userNotFound
                case .wrongPassword:
                    throw Error.wrongPassword
                default:
                    throw error
                }
            } else {
                throw error
            }
        }
    }
    package func getUser(token: GoogleToken) async throws -> UserID {
        logger.start()
        
        if let user = Auth.auth().currentUser {
            return UserID(user.uid)
        }
        
        let googleCredential  = GoogleAuthProvider.credential(withIDToken: token.idToken,
                                                       accessToken: token.accessToken)
        let result = try await Auth.auth().signIn(with: googleCredential )
        return UserID(result.user.uid)
    }
    
    private var tickets: Deque<CreateFormTicket> = []
    package func appendTicket(_ ticket: CreateFormTicket) {
        self.tickets.append(ticket)
    }
    
    var emailRegisterForms: [CreateFormTicket:EmailRegisterForm.ID] = [:]
    var googleRegisterForms: [CreateFormTicket: GoogleRegisterForm.ID] = [:]
    package func getEmailRegisterForm(ticket: CreateFormTicket) async -> EmailRegisterForm.ID? {
        guard ticket.formType == .email else { return nil }
        return emailRegisterForms[ticket]
    }
    package func getGoogleRegisterForm(ticket: CreateFormTicket) async -> GoogleRegisterForm.ID? {
        guard ticket.formType == .google else { return nil }
        return googleRegisterForms[ticket]
    }
    
    
    // MARK: action
    package func createFormsFromTickets() {
        logger.start()
        
        // capture
        let accountHub = self.id
        
        // mutate
        while tickets.isEmpty == false {
            let ticket = tickets.removeFirst()
            switch ticket.formType {
            case .email:
                let registerFormRef = EmailRegisterForm(accountHub: accountHub,
                                                        ticket: ticket)
                self.emailRegisterForms[ticket] = registerFormRef.id

            case .google:
                let googleRegisterFormRef = GoogleRegisterForm(accountHub: accountHub,
                                                               ticket: ticket)
                self.googleRegisterForms[ticket] = googleRegisterFormRef.id
            }
        }
    }
    
    
    // MARK: value
    @MainActor
    package struct ID: AccountHubIdentity {
        let value = "AccountHub"
        nonisolated init() { }
        
        package var isExist: Bool {
            AccountHubManager.container[self] != nil
        }
        package var ref: AccountHub? {
            AccountHubManager.container[self]
        }
    }
    package enum Error: String, Swift.Error {
        case userNotFound
        case wrongPassword
    }
}


// MARK: ObjectManager
@MainActor
fileprivate final class AccountHubManager: Sendable {
    // MARK: state
    fileprivate static var container: [AccountHub.ID: AccountHub] = [:]
    fileprivate static func register(_ object: AccountHub) {
        container[object.id] = object
    }
}
