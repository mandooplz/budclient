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
final class AccountHub {
    // MARK: core
    static let shared = AccountHub()
    
    // MARK: state
    func isExist(email: String, password: String) async throws -> Bool {
        do {
            let _ = try await Auth.auth().signIn(withEmail: email, password: password)
        } catch let error as NSError {
            if let errorCode = AuthErrorCode.Code(rawValue: error.code) {
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
    
    var tickets: Set<Ticket> = []
    var registerForms: [Ticket:RegisterForm.ID] = [:]
    
    
    // MARK: action
    func generateForms() {
        // mutate
        for ticket in tickets {
            let registerFormRef = RegisterForm(accountHubRef: self,
                                               ticket: ticket)
            self.registerForms[ticket] = registerFormRef.id
            tickets.remove(ticket)
        }
    }
    
    
    // MARK: value
    struct Ticket: Sendable, Hashable {
        let value: UUID
        
        init(value: UUID = UUID()) {
            self.value = value
        }
    }
    enum Error: String, Swift.Error {
        case userNotFound
        case wrongPassword
    }
    
}


