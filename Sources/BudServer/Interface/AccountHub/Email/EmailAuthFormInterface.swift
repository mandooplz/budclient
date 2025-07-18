//
//  EmailAuthFormInterface.swift
//  BudClient
//
//  Created by 김민우 on 7/18/25.
//
import Foundation


// MARK: Interface
package protocol EmailAuthFormInterface: Sendable {
    associatedtype ID: EmailAuthFormIdentity where ID.Object == Self
    
    // MARK: core
    init(email: String, password: String) async
    func delete() async
    
    
    // MARK: state
    nonisolated var id: ID { get async }
    
    var result: Result<UserID, EmailAuthFormError>? { get async }
    
    
    // MARK: action
    func submit() async
}


package protocol EmailAuthFormIdentity: Sendable, Hashable {
    associatedtype Object: EmailAuthFormInterface where Object.ID == Self
    
    var isExist: Bool { get async }
    var ref: Object? { get async }
}



// MARK: Values
package enum EmailAuthFormError: Swift.Error {
    case userNotFound, wrongPassword
    case unknown(Error)
}
