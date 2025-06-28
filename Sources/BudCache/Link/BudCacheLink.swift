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
    private let budServerLink: BudServerLink
    private var emailCredential: EmailCredential?
    package init(mode: SystemMode, budServerLink: BudServerLink) {
        self.mode = mode
        self.budServerLink = budServerLink
    }
    
    
    // MARK: state
    package func getUserId() async throws -> String {
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
    package mutating func setEmailCredential(_ credential: EmailCredential) async {
        switch mode {
        case .test:
            await MainActor.run {
                BudCacheMock.shared.emailCredential = credential.forMock()
            }
        case .real:
            self.emailCredential = credential
            return
        }
    }
    
    
    // MARK: action
    package func signIn() async throws {
        switch mode {
        case .test:
            await BudCacheMock.shared.signIn()
        case .real:
            if let user = Auth.auth().currentUser { return }
        }
    }
    
    
    
    // MARK: value
    package struct EmailCredential: Sendable {
        package let email: String
        package let password: String
        
        internal func forMock() -> BudCacheMock.EmailCredential {
            return .init(email: self.email, password: self.password)
        }
    }
    package enum Error: String, Swift.Error {
        case userIdIsNil
    }
}
