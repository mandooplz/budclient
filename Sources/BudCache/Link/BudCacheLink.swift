//
//  BudCacheLink.swift
//  BudClient
//
//  Created by 김민우 on 6/28/25.
//
import Foundation
import Tools
import FirebaseAuth
import BudServer


// MARK: Link
package struct BudCacheLink: Sendable {
    // MARK: core
    private let mode: SystemMode
    package init(mode: SystemMode) {
        self.mode = mode
    }
    
    
    // MARK: state
    package func getUserId() async throws(Error) -> String {
        switch mode {
        case .test:
            guard let userId = await BudCacheMock.shared.userId else {
                throw Error.userIdIsNil
            }
            return userId
        case .real:
            guard let user = Auth.auth().currentUser else {
                throw Error.userIdIsNil
            }
            return user.uid
        }
    }
    package func setEmailCredential(_ credential: EmailCredential) async throws {
        switch mode {
        case .test:
            await MainActor.run {
                BudCacheMock.shared.emailCredential = credential.forMock()
            }
        case .real:
            if Auth.auth().currentUser != nil { return }
            
            let _ = try await Auth.auth().signIn(withEmail: credential.email,
                                                 password: credential.password)
        }
    }
    
    
    // MARK: action
    package func signIn() async throws {
        switch mode {
        case .test:
            await BudCacheMock.shared.signIn()
        case .real:
            if Auth.auth().currentUser != nil {
                return
            } else {
                throw Error.emailCredentialNotSet
            }
            
        }
    }
    
    
    
    // MARK: value
    package struct EmailCredential: Sendable {
        package let email: String
        package let password: String
        
        package init(email: String, password: String) {
            self.email = email
            self.password = password
        }
        
        internal func forMock() -> BudCacheMock.EmailCredential {
            return .init(email: self.email, password: self.password)
        }
    }
    package enum Error: String, Swift.Error {
        case userIdIsNil
        case emailCredentialNotSet
    }
}
