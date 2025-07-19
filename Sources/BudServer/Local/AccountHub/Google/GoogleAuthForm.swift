//
//  GoogleAuthForm.swift
//  BudClient
//
//  Created by 김민우 on 7/18/25.
//
import Foundation
import Values
import FirebaseAuth
import FirebaseCore

private let logger = BudLogger("GoogleAuthForm")


// MARK: Object
@MainActor
package final class GoogleAuthForm: GoogleAuthFormInterface {
    // MARK: core
    package init(token: GoogleToken) async {
        self.token = token
        
        GoogleAuthFormManager.register(self)
    }
    package func delete() async {
        GoogleAuthFormManager.unregister(self.id)
    }
    
    
    // MARK: state
    package nonisolated let id = ID()
    
    nonisolated let token: GoogleToken
    
    package var result: Result<UserID, GoogleAuthFormError>?
    
    
    // MARK: action
    package func submit() async {
        logger.start()
        
        // 현재 Firebase에서 구글 이메일 비밀번호로 로그인되어있는지 확인
        if let firebaseUser = Auth.auth().currentUser {
            let isEmailPasswordUser = firebaseUser.providerData.lazy
                .map { $0.providerID == "google.com" }
                .contains(true)
            
            guard isEmailPasswordUser == false else {
                let user = UserID(firebaseUser.uid)
                self.result = .success(user)
                logger.info("Google 로그인이 되어 있어 조기종료합니다.")
                return
            }
        }
        
        
        let firebaseGoogleCredential  = GoogleAuthProvider.credential(
            withIDToken: token.idToken,
            accessToken: token.accessToken)
        
        do {
            let result = try await Auth.auth().signIn(with: firebaseGoogleCredential)
            self.result = .success(UserID(result.user.uid)) 
        } catch let error as NSError {
            // 에러 코드가 '계정 충돌'인 경우 특별 처리
            if let errorCode = AuthErrorCode(rawValue: error.code) {
                switch errorCode {
                case .accountExistsWithDifferentCredential:
                    result = .failure(.accountExistsWithDifferentCredential)
                case .invalidCredential:
                    result = .failure(.invalidCredential)
                default:
                    result = .failure(.unknown(error))
                }
            }
            return
        } catch {
            result = .failure(.unknown(error))
            return
        }
    }
    
    
    // MARK: value
    @MainActor
    package struct ID: GoogleAuthFormIdentity {
        let value = UUID()
        nonisolated init() { }
        
        package var isExist: Bool {
            GoogleAuthFormManager.container[self] != nil
        }
        package var ref: GoogleAuthForm? {
            GoogleAuthFormManager.container[self]
        }
    }
}


// MARK: ObjectManager
@MainActor
fileprivate final class GoogleAuthFormManager: Sendable {
    // MARK: state
    fileprivate static var container: [GoogleAuthForm.ID: GoogleAuthForm] = [:]
    fileprivate static func register(_ object: GoogleAuthForm) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: GoogleAuthForm.ID) {
        container[id] = nil
    }
}

