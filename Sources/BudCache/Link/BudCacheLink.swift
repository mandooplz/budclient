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

// BudClient(budCacheMockRef:)를 통해 BudCacheMock을 주입할 수 있다.
// 이를 통해 BudCacheLink의 이니셜라이저로 Mock 인스턴스를 주입할 수 있다.
// MARK: Link
package struct BudCacheLink: Sendable {
    // MARK: core
    private let mode: SystemMode
    private let budCacheMockRef: BudCacheMock
    package init(mode: SystemMode, budCacheMockRef: BudCacheMock) {
        self.mode = mode
        self.budCacheMockRef = budCacheMockRef
    }
    
    
    // MARK: state
    package func getUserId() async -> String? {
        switch mode {
        case .test:
            return await budCacheMockRef.userId
        case .real:
            return Auth.auth().currentUser?.uid
        }
    }
    package func setEmailCredential(_ credential: EmailCredential) async throws {
        switch mode {
        case .test:
            await MainActor.run {
                budCacheMockRef.emailCredential = credential.forMock()
            }
        case .real:
            if Auth.auth().currentUser != nil { return }
            
            let _ = try await Auth.auth().signIn(withEmail: credential.email,
                                                 password: credential.password)
        }
    }
    package func isEmailCredentialSet() async -> Bool {
        switch mode {
        case .test:
            return await budCacheMockRef.emailCredential != nil
        case .real:
            return Auth.auth().currentUser != nil
        }
    }
    
    
    // MARK: action
    package func signIn() async throws {
        switch mode {
        case .test:
            await budCacheMockRef.signIn()
        case .real:
            if Auth.auth().currentUser != nil {
                return
            } else {
                throw Error.emailCredentialNotSet
            }
            
        }
    }
    package func signOut() async throws {
        
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
