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



// MARK: Object
@MainActor
package final class EmailAuthForm: EmailAuthFormInterface {
    // MARK: core
    private let logger = BudLogger("EmailAuthForm")
    package init(email: String, password: String) async {
        self.email = email
        self.password = password
    }
    
    
    // MARK: state
    nonisolated let email: String
    nonisolated let password: String
    
    package var result: Result<UserID, EmailAuthFormError>?
    
    
    // MARK: action
    package func submit() async {
        logger.start()
        
        // 현재 Firebase에서 이메일, 비밀번호로 로그인되어있는지 확인
        if let firebaseUser = Auth.auth().currentUser {
            let isEmailPasswordUser = firebaseUser.providerData.lazy
                .map { $0.providerID == "password" }
                .contains(true)
            
            guard isEmailPasswordUser == false else {
                let user = UserID(firebaseUser.uid)
                self.result = .success(user)
                logger.end("Email 로그인이 되어 있어 조기종료합니다.")
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
}
