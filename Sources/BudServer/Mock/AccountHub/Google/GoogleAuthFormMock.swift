//
//  GoogleAuthFormMock.swift
//  BudClient
//
//  Created by 김민우 on 7/18/25.
//
import Foundation
import Values



// MARK: Object
@Server
package final class GoogleAuthFormMock: GoogleAuthFormInterface {
    // MARK: core
    private let logger = BudLogger("GoogleAuthFormMock")
    package init(token: GoogleToken) async {
        self.token = token
    }
    
    
    // MARK: state
    
    nonisolated let token: GoogleToken

    package var result: Result<UserID, GoogleAuthFormError>?
    
    
    // MARK: action
    package func submit() async {
        let accountHubRef = AccountHubMock.shared
        
        let account = accountHubRef.accounts
            .compactMap { $0.ref }
            .first { $0.token == self.token }
        
        guard let account else {
            self.result = .failure(.userNotFound)
            logger.failure("Google 로그인 계정이 존재하지 않습니다.")
            return
        }
        
        self.result = .success(account.user)
    }
}

