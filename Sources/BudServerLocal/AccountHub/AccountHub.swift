//
//  AccountHub.swift
//  BudClient
//
//  Created by 김민우 on 6/24/25.
//
import Foundation
import Values
import FirebaseAuth


// MARK: Object
@Server
package final class AccountHub {
    // MARK: core
    package static let shared = AccountHub()
    private init() { }
    
    
    // MARK: state
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
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            return result.user.uid.toUserID()
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
        if let user = Auth.auth().currentUser {
            return user.uid.toUserID()
        }
        
        let googleCredential  = GoogleAuthProvider.credential(withIDToken: token.idToken,
                                                       accessToken: token.accessToken)
        let result = try await Auth.auth().signIn(with: googleCredential )
        return result.user.uid.toUserID()
    }
    
    package var emailTickets: Set<CreateEmailForm> = []
    package var emailRegisterForms: [CreateEmailForm:EmailRegisterFormID] = [:]
    
    package var googleTickets: Set<CreateGoogleForm> = []
    package var googleRegisterForms: [CreateGoogleForm: GoogleRegisterFormID] = [:]
    
    
    // MARK: action
    package func updateEmailForms() {
        // mutate
        for ticket in emailTickets {
            let registerFormRef = EmailRegisterForm(accountHubRef: self,
                                               ticket: ticket)
            self.emailRegisterForms[ticket] = registerFormRef.id
            emailTickets.remove(ticket)
        }
    }
    package func updateGoogleForms() {
        // mutate
        for ticket in googleTickets {
            let googleRegisterFormRef = GoogleRegisterForm(accountHubRef: self,
                                                           ticket: ticket)
            self.googleRegisterForms[ticket] = googleRegisterFormRef.id
            googleTickets.remove(ticket)
        }
    }
    
    
    // MARK: value
    package enum Error: String, Swift.Error {
        case userNotFound, wrongPassword
    }
}


