//
//  AccountHubMock.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation
import Values
import Collections


// MARK: Object
@Server
package final class AccountHubMock: AccountHubInterface {
    // MARK: core
    static let shared = AccountHubMock()
    private init() { }
    
    
    // MARK: state
    package nonisolated let id = ID()
    
    var accounts: Set<AccountMock.ID> = [AccountMock(email: "test@test.com", password: "123456").id]
    
    package nonisolated let budClientInfoFormType = BudClientInfoFormMock.self
    
    package nonisolated let emailRegisterFormType = EmailRegisterFormMock.self
    package nonisolated let googleRegisterFormType = GoogleRegisterFormMock.self
    
    package nonisolated let emailAuthFormType = EmailAuthFormMock.self
    package nonisolated let googleAuthFormType = GoogleAuthFormMock.self
    

    
    // MARK: value
    @Server
    package struct ID: AccountHubIdentity {
        let value = UUID()
        nonisolated init() { }
        
        package var isExist: Bool {
            true
        }
        package var ref: AccountHubMock? {
            AccountHubMock.shared
        }
    }
}
