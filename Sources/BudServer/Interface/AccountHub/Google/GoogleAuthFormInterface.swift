//
//  GoogleAuthFormInterface.swift
//  BudClient
//
//  Created by 김민우 on 7/18/25.
//
import Foundation
import Values


// MARK: Interface
package protocol GoogleAuthFormInterface: Sendable {
    // MARK: core
    init(token: GoogleToken) async
    
    // MARK: state
    var result: Result<UserID, GoogleAuthFormError>? { get async }
    
    // MARK: action
    func submit() async
}



// MARK: Values
package enum GoogleAuthFormError: Swift.Error {
    case userNotFound
    case accountExistsWithDifferentCredential // 기존 이메일 존재
    case invalidCredential // token 유효시간 만료
    case unknown(Error)
}
