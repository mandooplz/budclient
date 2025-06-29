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
    internal static let shared = AccountHub()
    private init() { }
    
    
    // MARK: state
    internal func isExist(email: String, password: String) async throws -> Bool {
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
    internal func getUserId(email: String, password: String) async throws -> String {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            return result.user.uid
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
    internal func getUserId(googleIdToken: String, googleAccessToken: String) async throws -> String {
        if let user = Auth.auth().currentUser {
            return user.uid
        }
        
        do {
            let credential = GoogleAuthProvider.credential(withIDToken: googleIdToken,
                                                           accessToken: googleAccessToken)
            let result = try await Auth.auth().signIn(with: credential)
            return result.user.uid
        } catch {
            throw UnknownIssue(error)
        }
    }
    
    internal var emailTickets: Set<Ticket> = []
    internal var emailRegisterForms: [Ticket:EmailRegisterForm.ID] = [:]
    
    internal var googleTickets: Set<Ticket> = []
    internal var googleRegisterForms: [Ticket: GoogleRegisterForm.ID] = [:]
    
    
    // MARK: action
    internal func updateEmailForms() {
        // mutate
        for ticket in emailTickets {
            let registerFormRef = EmailRegisterForm(accountHubRef: self,
                                               ticket: ticket)
            self.emailRegisterForms[ticket] = registerFormRef.id
            emailTickets.remove(ticket)
        }
    }
    internal func updateGoogleForms() {
        // mutate
        for ticket in googleTickets {
            let googleRegisterFormRef = GoogleRegisterForm(accountHubRef: self,
                                                           ticket: ticket)
            self.googleRegisterForms[ticket] = googleRegisterFormRef.id
            googleTickets.remove(ticket)
        }
    }
    
    
    // MARK: value
    internal struct Ticket: Sendable, Hashable {
        internal let value: UUID
        
        internal init(value: UUID = UUID()) {
            self.value = value
        }
    }
}


