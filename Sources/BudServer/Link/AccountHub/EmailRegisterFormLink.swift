//
//  RegisterFormLink.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation
import Tools
import FirebaseAuth


// MARK: Link
package struct EmailRegisterFormLink: Sendable {
    // MARK: core
    private nonisolated let mode: Mode
    internal init(mode: Mode) {
        self.mode = mode
    }
    
    // MARK: state
    package func setEmail(_ value: String) async {
        switch mode {
        case .test(let mock):
            await MainActor.run {
                let emailRegisterFormRef = EmailRegisterFormMockManager.get(mock)!
                emailRegisterFormRef.email = value
            }
        case .real(let object):
            
            await Server.run {
                let emailRegisterFormRef = EmailRegisterFormManager.get(object)!
                emailRegisterFormRef.email = value
            }
        }
    }
    package func setPassword(_ value: String) async {
        switch mode {
        case .test(let mock):
            await MainActor.run {
                let registerFormRef = EmailRegisterFormMockManager.get(mock)!
                registerFormRef.password = value
            }
        case .real(let object):
            let registerFormRef = await EmailRegisterFormManager.get(object)!
            
            await Server.run {
                registerFormRef.password = value
            }
        }
    }
        
    package func getIssue() async -> (any Issuable)? {
            switch mode {
            case .test(let mock):
                await MainActor.run {
                    let registerFormRef = EmailRegisterFormMockManager.get(mock)!
                    return registerFormRef.issue
                }
            case .real(let object):
                await Server.run {
                    let registerFormRef = EmailRegisterFormManager.get(object)!
                    return registerFormRef.issue
                }
            }
        }
        
    
    // MARK: action
    package func submit() async {
        switch mode {
        case .test(let mock):
            await MainActor.run {
                let registerFormRef = EmailRegisterFormMockManager.get(mock)!
                registerFormRef.submit()
            }
        case .real(let object):
            let registerFormRef = await EmailRegisterFormManager.get(object)!
            await registerFormRef.submit()
        }
    }
    package func remove() async {
        switch mode {
        case .test(let mock):
            await MainActor.run {
                let registerFormRef = EmailRegisterFormMockManager.get(mock)!
                registerFormRef.remove()
            }
        case .real(let object):
            let registerFormRef = await EmailRegisterFormManager.get(object)!
            await registerFormRef.remove()
        }
    }
    
    
    // MARK: value
    package struct ID: Sendable, Hashable {
        package let value: UUID
        
        internal init(_ realId: EmailRegisterForm.ID) {
            self.value = realId.value
        }
        
        fileprivate func forReal() -> EmailRegisterForm.ID {
            return .init(value: self.value)
        }
    }
    internal enum Mode: Sendable {
        case test(mock: EmailRegisterFormMock.ID)
        case real(object: EmailRegisterForm.ID)
    }
}
