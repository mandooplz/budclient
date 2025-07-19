//
//  GoogleFormMock.swift
//  BudClient
//
//  Created by 김민우 on 6/29/25.
//
import Foundation
import Values



// MARK: Object
@Server
package final class GoogleRegisterFormMock: GoogleRegisterFormInterface {
    // MARK: core
    private let logger = BudLogger("GoogleRegisterFormMock")
    package init(token: GoogleToken) {
        self.token = token
    }
    
    
    // MARK: state
    nonisolated let token: GoogleToken
    
    package var error: GoogleRegisterFormError?
    
    
    // MARK: action
    package func submit() {
        // capture
        let accountHubRef = AccountHubMock.shared
        
        let account = accountHubRef.accounts.lazy
            .compactMap { $0.ref }
            .first { $0.token == self.token }
        
        guard account == nil else {
            self.error = .userAlreadyExist
            logger.failure("Google 로그인 계정이 이미 존재합니다.")
            return
        }
        
        // mutate
        let accountRef = AccountMock(token: token)
        accountHubRef.accounts.insert(accountRef.id)
    }
}

