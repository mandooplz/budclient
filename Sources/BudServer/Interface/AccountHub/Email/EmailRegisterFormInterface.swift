//
//  EmailRegisterFormInterface.swift
//  BudClient
//
//  Created by 김민우 on 7/11/25.
//
import Foundation
import Values


// MARK: Interface
package protocol EmailRegisterFormInterface: Sendable {
    // MARK: core
    init(email: String, password: String) async
    
    
    // MARK: state
    var error: EmailRegisterFormError? { get async }
    
    
    // MARK: action
    func submit() async
}


// MARK: Value
package enum EmailRegisterFormError: Swift.Error {
    case userWithEmailAlreadyExist
    case unknown(Error)
}
