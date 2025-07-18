//
//  GoogleRegisterFormInterface.swift
//  BudClient
//
//  Created by 김민우 on 7/11/25.
//
import Foundation
import Values
import CryptoKit


// MARK: Interface
package protocol GoogleRegisterFormInterface: Sendable {
    // MARK: core
    init(token: GoogleToken) async
    
    
    // MARK: state
    var error: GoogleRegisterFormError? { get async }
    
    
    // MARK: action
    func submit() async
}


// MARK: Values
package enum GoogleRegisterFormError: Swift.Error {
    case userAlreadyExist
    case accountExistsWithDifferentCredential // 다른 CredentialProvider와 중복
    case invalidCredential // token 유효기간만료
    case unknown(Error)
}

package struct GoogleToken: Sendable, Hashable {
    package let idToken: String
    package let accessToken: String
    
    // MARK: core
    package init(idToken: String, accessToken: String) {
        self.idToken = idToken
        self.accessToken = accessToken
    }
    
    static func random() -> GoogleToken {
        GoogleToken(idToken: Token.random().value,
                    accessToken: Token.random().value)
    }
    
    
    // MARK: operator
    package func getValue() -> String {
        let combined = idToken + ":" + accessToken
        
        // SHA256 해시를 사용한 결정론적 user id 생성
        let data = combined.data(using: .utf8)!
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
