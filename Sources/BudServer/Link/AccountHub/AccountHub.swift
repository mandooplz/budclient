//
//  AccountHub.swift
//  BudClient
//
//  Created by 김민우 on 6/24/25.
//
import Foundation
import Tools
import FirebaseAuth


// MARK: Object
@Server
internal final class AccountHub {
    // MARK: core
    static let shared = AccountHub()
    private init() { }
    
    
    // MARK: state
    func isExist(email: String, password: String) async throws -> Bool {
        do {
            let _ = try await Auth.auth().signIn(withEmail: email, password: password)
        } catch let error as NSError {
            if let errorCode = AuthErrorCode(rawValue: error.code) {
                switch errorCode {
                case .userNotFound:
                    throw AccountHubLink.Error.userNotFound
                case .wrongPassword:
                    throw AccountHubLink.Error.wrongPassword
                default:
                    throw error
                }
            } else {
                throw error
            }
        }
        
        return true
    }
    func getUser(email: String, password: String) async throws -> UserID {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            return result.user.uid.toUserID()
        } catch let error as NSError {
            if let errorCode = AuthErrorCode(rawValue: error.code) {
                switch errorCode {
                case .userNotFound:
                    throw AccountHubLink.Error.userNotFound
                case .wrongPassword:
                    throw AccountHubLink.Error.wrongPassword
                default:
                    throw error
                }
            } else {
                throw error
            }
        }
    }
    func getUser(token: GoogleToken) async throws -> UserID {
        if let user = Auth.auth().currentUser {
            return user.uid.toUserID()
        }
        
        let googleCredential  = GoogleAuthProvider.credential(withIDToken: token.idToken,
                                                       accessToken: token.accessToken)
        let result = try await Auth.auth().signIn(with: googleCredential )
        return result.user.uid.toUserID()
    }
    
    var emailTickets: Set<Ticket> = []
    var emailRegisterForms: [Ticket:EmailRegisterForm.ID] = [:]
    
    var googleTickets: Set<Ticket> = []
    var googleRegisterForms: [Ticket: GoogleRegisterForm.ID] = [:]
    
    
    // MARK: action
    func updateEmailForms() {
        // mutate
        for ticket in emailTickets {
            let registerFormRef = EmailRegisterForm(accountHubRef: self,
                                               ticket: ticket)
            self.emailRegisterForms[ticket] = registerFormRef.id
            emailTickets.remove(ticket)
        }
    }
    func updateGoogleForms() {
        // mutate
        for ticket in googleTickets {
            let googleRegisterFormRef = GoogleRegisterForm(accountHubRef: self,
                                                           ticket: ticket)
            self.googleRegisterForms[ticket] = googleRegisterFormRef.id
            googleTickets.remove(ticket)
        }
    }
    
    
    // MARK: value
    struct Ticket: Sendable, Hashable {
        let value: UUID
        
        init(value: UUID = UUID()) {
            self.value = value
        }
    }
}


