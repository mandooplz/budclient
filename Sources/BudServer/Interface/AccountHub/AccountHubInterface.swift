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
    associatedtype EmailRegisterFormID: EmailRegisterFormIdentity
    associatedtype GoogleRegisterFormID: GoogleRegisterFormIdentity
    
    // MARK: state
    nonisolated var id: ID { get }
    
    func getGoogleClientID(for: String) async -> String?;
    
    func isExist(email: String, password: String) async throws -> Bool
    func getUser(email: String, password: String) async throws -> UserID
    func getUser(token: GoogleToken) async throws -> UserID;
    
    func appendTicket(_: CreateFormTicket) async
    
    func getEmailRegisterForm(ticket: CreateFormTicket) async -> EmailRegisterFormID?;
    func getGoogleRegisterForm(ticket: CreateFormTicket) async -> GoogleRegisterFormID?;
    
    // MARK: action
    func createFormsFromTickets() async
}


package protocol AccountHubIdentity: Sendable, Hashable {
    associatedtype Object: AccountHubInterface where Object.ID == Self
    
    var isExist: Bool { get async }
    var ref: Object? { get async }
}


// MARK: Value
package enum AccountHubError: String, Swift.Error {
    case userNotFound, wrongPassword
}

package struct UserID: Identity {
    package let value: String
    
    package init(_ value: String) {
        self.value = value
    }
    
    package init() {
        self.value = UUID().uuidString
    }
}

package struct CreateFormTicket: Sendable, Hashable {
    let value: UUID = UUID()
    package let formType: FormType
    
    package init(formType: FormType) {
        self.formType = formType
    }
    
    package enum FormType: Sendable {
        case email
        case google
    }
}

package struct CreateEmailForm: Sendable, Hashable {
    let value: UUID
    
    package init(value: UUID = UUID()) {
        self.value = value
    }
}

package struct CreateGoogleForm: Sendable, Hashable {
    let value: UUID
    
    package init(value: UUID = UUID()) {
        self.value = value
    }
}

