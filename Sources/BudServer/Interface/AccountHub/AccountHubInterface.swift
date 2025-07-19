//
//  AccountHubInterface.swift
//  BudClient
//
//  Created by 김민우 on 7/10/25.
//
import Foundation
import Values


// MARK: Interface
package protocol AccountHubInterface: Sendable {
    associatedtype ID: AccountHubIdentity where ID.Object == Self
    associatedtype BudClientInfoFormObject: BudClientInfoFormInterface
    associatedtype EmailRegisterFormObject: EmailRegisterFormInterface
    associatedtype GoogleRegisterFormObject: GoogleRegisterFormInterface
    associatedtype EmailAuthFormObject: EmailAuthFormInterface
    associatedtype GoogleAuthFormObject: GoogleAuthFormInterface
    
    // MARK: state
    nonisolated var id: ID { get async }
    
    nonisolated var budClientInfoFormType: BudClientInfoFormObject.Type { get }
    
    nonisolated var emailRegisterFormType: EmailRegisterFormObject.Type { get }
    nonisolated var googleRegisterFormType: GoogleRegisterFormObject.Type { get }
    
    nonisolated var emailAuthFormType: EmailAuthFormObject.Type { get }
    nonisolated var googleAuthFormType: GoogleAuthFormObject.Type { get }
}


package protocol AccountHubIdentity: Sendable, Hashable {
    associatedtype Object: AccountHubInterface where Object.ID == Self
    
    var isExist: Bool { get async }
    var ref: Object? { get async }
}


// MARK: Value
package struct UserID: IDRepresentable {
    package let value: String
    
    package init(_ value: String) {
        self.value = value
    }
    
    package init() {
        self.value = UUID().uuidString
    }
}
