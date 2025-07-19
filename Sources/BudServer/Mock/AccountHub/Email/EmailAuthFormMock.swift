//
//  EmailAuthFormMock.swift
//  BudClient
//
//  Created by 김민우 on 7/18/25.
//
import Foundation
import Values

private let logger = BudLogger("EmailAuthFormMock")


// MARK: Object
@Server
package final class EmailAuthFormMock: EmailAuthFormInterface {
    // MARK: core
    package init(email: String, password: String) async {
        self.email = email
        self.password = password
        
        EmailAuthFormMockManager.register(self)
    }
    package func delete() async {
        EmailAuthFormMockManager.unregister(self.id)
    }
    
    
    // MARK: state
    package nonisolated let id = ID()
    
    nonisolated let email: String
    nonisolated let password: String
    
    package var result: Result<UserID, EmailAuthFormError>?
    
    
    
    // MARK: action
    package func submit() async {
        let accountHubRef = AccountHubMock.shared
        
        // user email 존재여부 확인
        let account = accountHubRef.accounts
            .compactMap { $0.ref }
            .first { $0.email == self.email }
        
        guard let account else {
            self.result = .failure(.userNotFound)
            logger.failure("동일한 Email을 가진 사용자가 이미 존재합니다.")
            return
        }
        
        
        // email 확인
        guard account.password == self.password else {
            self.result = .failure(.wrongPassword)
            logger.failure("Email은 맞지만 Password가 틀렸습니다.")
            return
        }
        
        self.result = .success(account.user)
    }
    
    
    // MARK: value
    @Server
    package struct ID: EmailAuthFormIdentity {
        let value = UUID()
        nonisolated init() { }
        
        package var isExist: Bool {
            EmailAuthFormMockManager.container[self] != nil
        }
        package var ref: EmailAuthFormMock? {
            EmailAuthFormMockManager.container[self]
        }
    }
}


// MARK: ObjectManager
@Server
fileprivate final class EmailAuthFormMockManager: Sendable {
    // MARK: state
    fileprivate static var container: [EmailAuthFormMock.ID: EmailAuthFormMock] = [:]
    fileprivate static func register(_ object: EmailAuthFormMock) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: EmailAuthFormMock.ID) {
        container[id] = nil
    }
}
