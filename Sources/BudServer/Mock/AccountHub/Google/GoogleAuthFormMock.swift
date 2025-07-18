//
//  GoogleAuthFormMock.swift
//  BudClient
//
//  Created by 김민우 on 7/18/25.
//
import Foundation
import Values

private let logger = WorkFlow.getLogger(for: "GoogleAuthFormMock")


// MARK: Object
@Server
package final class GoogleAuthFormMock: GoogleAuthFormInterface {
    // MARK: core
    package init(token: GoogleToken) async {
        self.token = token
        
        GoogleAuthFormMockManager.register(self)
    }
    package func delete() async {
        GoogleAuthFormMockManager.unregister(self.id)
    }
    
    
    // MARK: state
    package nonisolated let id = ID()
    
    nonisolated let token: GoogleToken

    package var result: Result<UserID, GoogleAuthFormError>?
    
    
    // MARK: action
    package func submit() async {
        let accountHubRef = AccountHubMock.shared
        
        let account = accountHubRef.accounts
            .compactMap { $0.ref }
            .first { $0.token == self.token }
        
        guard let account else {
            self.result = .failure(.userNotFound)
            logger.failure("Google 로그인 계정이 존재하지 않습니다.")
            return
        }
        
        self.result = .success(account.user)
    }
    
    
    // MARK: value
    @Server
    package struct ID: GoogleAuthFormIdentity {
        let value = UUID()
        nonisolated init() { }
        
        package var isExist: Bool {
            GoogleAuthFormMockManager.container[self] != nil
        }
        package var ref: GoogleAuthFormMock? {
            GoogleAuthFormMockManager.container[self]
        }
    }
}


// MARK: ObjectManager
@Server
fileprivate final class GoogleAuthFormMockManager: Sendable {
    // MARK: state
    fileprivate static var container: [GoogleAuthFormMock.ID: GoogleAuthFormMock] = [:]
    fileprivate static func register(_ object: GoogleAuthFormMock) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: GoogleAuthFormMock.ID) {
        container[id] = nil
    }
}

