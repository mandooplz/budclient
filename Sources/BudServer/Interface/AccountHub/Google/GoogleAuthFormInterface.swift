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
    associatedtype ID: GoogleAuthFormIdentity where ID.Object == Self
    
    // MARK: core
    init(token: GoogleToken) async
    func delete() async
    
    
    // MARK: state
    nonisolated var id: ID { get async }
    
    var result: Result<UserID, GoogleAuthFormError>? { get async }
    
    
    // MARK: action
    func submit() async
}


package protocol GoogleAuthFormIdentity: Sendable, Hashable {
    associatedtype Object: GoogleAuthFormInterface where Object.ID == Self
    
    var isExist: Bool { get async }
    var ref: Object? { get async }
}



// MARK: Values
package enum GoogleAuthFormError: Swift.Error {
    case userNotFound
    case accountExistsWithDifferentCredential // 기존 이메일 존재
    case invalidCredential // token 유효시간 만료
    case unknown(Error)
}
