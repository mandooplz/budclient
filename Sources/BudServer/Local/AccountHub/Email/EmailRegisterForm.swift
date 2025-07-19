//
//  EmailRegisterForm.swift
//  BudClient
//
//  Created by 김민우 on 6/24/25.
//
import Foundation
import Values
import FirebaseAuth



// MARK: Object
@MainActor
package final class EmailRegisterForm: EmailRegisterFormInterface {
    // MARK: core
    private let logger = BudLogger("EmailRegisterForm")
    package init(email: String, password: String) {
        self.email = email
        self.password = password
    }
    
    
    // MARK: state
    nonisolated let email: String
    nonisolated let password: String
    
    package var error: EmailRegisterFormError?

    // MARK: action
    package func submit() async {
        // mutate
        do {
            try await Auth.auth().createUser(withEmail: email, password: password)
            // 성공적으로 계정이 생성되면, 이전의 에러 상태를 초기화해주는 것이 좋습니다.
            self.error = nil
        } catch {
            // Firebase Auth 에러는 NSError로 캐스팅하여 code를 확인할 수 있습니다.
            if let nsError = error as NSError?, nsError.code == AuthErrorCode.emailAlreadyInUse.rawValue {
                // 이메일이 이미 존재하는 에러(userWithEmailAlreadyExist)인 경우
                self.error = .userWithEmailAlreadyExist
            } else {
                // 그 외 다른 모든 에러인 경우 (네트워크 오류, 약한 비밀번호 등)
                self.error = .unknown(error)
            }
        }
    }
}
