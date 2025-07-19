//
//  EmailAuthFormInterface.swift
//  BudClient
//
//  Created by 김민우 on 7/18/25.
//
import Foundation


// MARK: Interface
package protocol EmailAuthFormInterface: Sendable {
    // MARK: core
    init(email: String, password: String) async
    
    // MARK: state
    var result: Result<UserID, EmailAuthFormError>? { get async }
    
    // MARK: action
    func submit() async
}


// MARK: Values
package enum EmailAuthFormError: Swift.Error {
    case userNotFound, wrongPassword
    case unknown(Error)
}
