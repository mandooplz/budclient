//
//  GoogleRegisterForm.swift
//  BudClient
//
//  Created by 김민우 on 6/29/25.
//
import Foundation
import Values
import FirebaseAuth



// MARK: Object
@Server
package final class GoogleRegisterForm: GoogleRegisterFormInterface {
    // MARK: core
    private let logger = BudLogger("GoogleRegisterForm")
    package init(token: GoogleToken) {
        self.token = token
    }
    
    // MARK: state
    nonisolated let token: GoogleToken
    
    package var error: GoogleRegisterFormError?
    
    
    // MARK: action
    package func submit() async {
        logger.start()

        // compute
        let googleCredential = GoogleAuthProvider.credential(withIDToken: token.idToken,
                                                       accessToken: token.accessToken)
        do {
            try await Auth.auth().signIn(with: googleCredential)
        } catch let error as NSError {
            // 에러 코드가 '계정 충돌'인 경우 특별 처리
            if let errorCode = AuthErrorCode(rawValue: error.code) {
                switch errorCode {
                case .accountExistsWithDifferentCredential:
                    self.error = .accountExistsWithDifferentCredential
                case .invalidCredential:
                    self.error = .invalidCredential
                default:
                    self.error = .unknown(error)
                }
            }
            return
        } catch {
            self.error = .unknown(error)
            return
        }
    }
}
