//
//  BudCacheMock.swift
//  BudClient
//
//  Created by 김민우 on 6/28/25.
//
import Foundation
import Tools
import BudServer


// MARK: BudCache
@MainActor
package final class BudCacheMock: Sendable {
    // MARK: core
    package static let shared = BudCacheMock()
    private init() { }
    
    
    // MARK: state
    package var userId: String?
    package var emailCredential: EmailCredential?
    
    
    // MARK: action
    package func signIn() async {
        // capture
        guard let email = emailCredential?.email,
              let password = emailCredential?.password else {
            self.userId = nil
            return
        }
        
        // compute
        let userId: String
        do {
            let budServerLink = try BudServerLink(mode: .test)
            let accountHubLink = budServerLink.getAccountHub()
            userId = try await accountHubLink.getUserId(email: email,
                                               password: password)
        } catch {
            return
        }
        
        // mutate
        self.userId = userId
    }
    
    
    // MARK: value
    package struct EmailCredential: Sendable {
        package let email: String
        package let password: String
        
        package init(email: String, password: String) {
            self.email = email
            self.password = password
        }
    }
    package enum Error: String, Swift.Error {
        case credentialIsNil
    }
}
