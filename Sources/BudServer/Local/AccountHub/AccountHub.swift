//
//  AccountHub.swift
//  BudClient
//
//  Created by 김민우 on 6/24/25.
//
import Foundation
import Values

private let logger = WorkFlow.getLogger(for: "AccountHub")


// MARK: Object
@MainActor
package final class AccountHub: AccountHubInterface {
    
    // MARK: core
    static let shared = AccountHub()
    private init() { }
    
    
    // MARK: state
    package nonisolated let id = ID()
    
    package nonisolated let budClientInfoFormType = BudClienInfoForm.self
    
    package nonisolated let emailRegisterFormType = EmailRegisterForm.self
    package nonisolated let googleRegisterFormType = GoogleRegisterForm.self
    
    package nonisolated let emailAuthFormType = EmailAuthForm.self
    package nonisolated let googleAuthFormType = GoogleAuthForm.self
    
    
    
    // MARK: value
    @MainActor
    package struct ID: AccountHubIdentity {
        let value = "AccountHub"
        nonisolated init() { }
        
        package var isExist: Bool {
            true
        }
        package var ref: AccountHub? {
            AccountHub.shared
        }
    }
    
    package enum Error: Swift.Error {
        case firebaseAppIsNotConfigured
    }
}
