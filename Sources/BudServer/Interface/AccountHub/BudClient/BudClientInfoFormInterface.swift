//
//  BudClientInfoFormInterface.swift
//  BudClient
//
//  Created by 김민우 on 7/18/25.
//
import Foundation


// MARK: Interface
package protocol BudClientInfoFormInterface: Sendable {
    // MARK: core
    init() async
    
    // MARK: state
    var googleClientId: String? { get async }
    
    // MARK: action
    func fetchGoogleClientId() async
}


// MARK: Values
package enum BudClientInfoFormError: Swift.Error {
    case unknown(Error)
}

