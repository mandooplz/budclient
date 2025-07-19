//
//  EmailAuthForm.swift
//  BudClient
//
//  Created by 김민우 on 7/18/25.
//
import Foundation
import Values
import FirebaseAuth
import FirebaseCore

private let logger = BudLogger("EmailAuthForm")


// MARK: Object
@MainActor
package final class EmailAuthForm: EmailAuthFormInterface {
    // MARK: core
    package init(email: String, password: String) async {
        self.email = email
        self.password = password
        
        EmailAuthFormManager.register(self)
    }
    package func delete() async {
        EmailAuthFormManager.unregister(self.id)
    }
    
    
    // MARK: state
    package nonisolated let id = ID()
    
    nonisolated let email: String
    nonisolated let password: String
    
    package var result: Result<UserID, EmailAuthFormError>?
    
    
    // MARK: action
    package func submit() async {
        logger.start()
        guard id.isExist else {
            logger.failure("EmailAuthForm이 존재하지 않아 실행취소됩니다.")
            return
        }
        
        // 현재 Firebase에서 이메일, 비밀번호로 로그인되어있는지 확인
        if let firebaseUser = Auth.auth().currentUser {
            let isEmailPasswordUser = firebaseUser.providerData.lazy
                .map { $0.providerID == "password" }
                .contains(true)
            
            guard isEmailPasswordUser == false else {
                let user = UserID(firebaseUser.uid)
                self.result = .success(user)
                logger.info("Email 로그인이 되어 있어 조기종료합니다.")
                return
            }
        }
        
        
        // 이메일, 비밀번호로 가입되어 있지 않다면 로그인 진행
        do {
            let firebaseUser = try await Auth.auth()
                .signIn(withEmail: email,password: password)
            
            let user = UserID(firebaseUser.user.uid)
            
            self.result = .success(user)
            
        } catch let error as NSError {
            if let errorCode = AuthErrorCode(rawValue: error.code) {
                switch errorCode {
                case .userNotFound:
                    self.result = .failure(.userNotFound)
                case .wrongPassword:
                    self.result = .failure(.wrongPassword)
                default:
                    self.result = .failure(.unknown(error))
                }
            } else {
                self.result = .failure(.unknown(error))
            }
        }
    }
    
    
    // MARK: value
    @MainActor
    package struct ID: EmailAuthFormIdentity {
        let value = UUID()
        nonisolated init() { }
        
        package var isExist: Bool {
            EmailAuthFormManager.container[self] != nil
        }
        package var ref: EmailAuthForm? {
            EmailAuthFormManager.container[self]
        }
    }
}


// MARK: ObjectManager
@MainActor
fileprivate final class EmailAuthFormManager: Sendable {
    // MARK: state
    fileprivate static var container: [EmailAuthForm.ID: EmailAuthForm] = [:]
    fileprivate static func register(_ object: EmailAuthForm) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: EmailAuthForm.ID) {
        container[id] = nil
    }
}
