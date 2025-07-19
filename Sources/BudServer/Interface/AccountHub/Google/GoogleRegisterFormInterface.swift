//
//  GoogleRegisterFormInterface.swift
//  BudClient
//
//  Created by 김민우 on 7/11/25.
//
import Foundation
import Values


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
