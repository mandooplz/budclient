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
package struct RegisterFormLink: Sendable {
    // MARK: core
    private nonisolated let mode: SystemMode
    private nonisolated let id: ID
    private nonisolated let idForMock: RegisterFormMock.ID!
    package init(mode: SystemMode,
                id: ID) {
        self.mode = mode
        self.id = id
        self.idForMock = nil
    }
    internal init(mode: SystemMode,
                  idForMock: RegisterFormMock.ID) {
        self.mode = mode
        self.id = ID(idForMock: idForMock)
        self.idForMock = idForMock
    }
    
    // MARK: state
    package func setEmail(_ value: String) async throws {
        switch mode {
        case .test:
            await MainActor.run {
                let registerFormRef = RegisterFormMockManager.get(idForMock)!
                registerFormRef.email = value
            }
        case .real:
            let registerForm = id.forReal()
            let registerFormRef = await RegisterFormManager.get(registerForm)!
            
            await Server.run {
                registerFormRef.email = value
            }
        }
    }
    package func setPassword(_ value: String) async throws {
        switch mode {
        case .test:
            await MainActor.run {
                let registerFormRef = RegisterFormMockManager.get(idForMock)!
                registerFormRef.password = value
            }
        case .real:
            let registerForm = id.forReal()
            let registerFormRef = await RegisterFormManager.get(registerForm)!
            
            await Server.run {
                registerFormRef.password = value
            }
        }
    }
        
    package func getIssue() async throws -> (any Issuable)? {
            switch mode {
            case .test:
                await MainActor.run {
                    let registerFormRef = RegisterFormMockManager.get(idForMock)!
                    return registerFormRef.issue
                }
            case .real:
                await Server.run {
                    let registerFormRef = RegisterFormManager.get(id.forReal())!
                    return registerFormRef.issue
                }
            }
        }
        
    
    // MARK: action
    package func submit() async throws {
        switch mode {
        case .test:
            await MainActor.run {
                let registerFormRef = RegisterFormMockManager.get(idForMock)!
                registerFormRef.submit()
            }
        case .real:
            let registerFormRef = await RegisterFormManager.get(id.forReal())!
            await registerFormRef.submit()
        }
    }
    package func remove() async throws {
        switch mode {
        case .test:
            await MainActor.run {
                let registerFormRef = RegisterFormMockManager.get(idForMock)!
                registerFormRef.remove()
            }
        case .real:
            let registerFormRef = await RegisterFormManager.get(id.forReal())!
            await registerFormRef.remove()
        }
    }
    
    
    // MARK: value
    package struct ID: Sendable, Hashable {
        package let value: UUID
        
        internal init(realId: RegisterForm.ID) {
            self.value = realId.value
        }
        
        internal init(idForMock: RegisterFormMock.ID) {
            self.value = idForMock.value
        }
        
        fileprivate func forReal() -> RegisterForm.ID {
            return .init(value: self.value)
        }
    }
}
