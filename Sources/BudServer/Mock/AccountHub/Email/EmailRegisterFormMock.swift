//
//  RegisterFormMock.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation
import Values

private let logger = WorkFlow.getLogger(for: "EmailRegisterFormMock")


// MARK: Object
@Server
package final class EmailRegisterFormMock: EmailRegisterFormInterface {
    // MARK: core
    package init(email: String, password: String) {
        self.email = email
        self.password = password
    }
    

    // MARK: state
    nonisolated let email: String
    nonisolated let password: String
    
    package var error: EmailRegisterFormError?

    
    // MARK: action
    package func submit() {
        // capture
        let accountHubRef = AccountHubMock.shared
        
        // compute
        let isDuplicate = accountHubRef.accounts.lazy
            .compactMap { $0.ref }
            .contains { $0.email == email }
        guard isDuplicate == false else {
            self.error = .userWithEmailAlreadyExist
            logger.failure("동일한 Email을 가진 사용자가 이미 존재합니다.")
            return
        }
        
        // mutate
        let account = AccountMock(email: email, password: password)
        accountHubRef.accounts.insert(account.id)
    }
}
