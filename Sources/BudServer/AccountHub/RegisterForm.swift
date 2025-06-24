//
//  RegisterFormLink.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation
import Tools
import BudServerMock
import FirebaseAuth


// MARK: Link
public struct RegisterFormLink: Sendable {
    // MARK: core
    private nonisolated let mode: SystemMode
    private nonisolated let id: ID
    private nonisolated let idForMock: RegisterFormMock.ID!
    public init(mode: SystemMode,
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
    public func setEmail(_ value: String) async throws {
        switch mode {
        case .test:
            await MainActor.run {
                let registerFormRef = RegisterFormMockManager.get(idForMock)!
                registerFormRef.email = value
            }
        case .real:
            fatalError()
        }
    }
    public func setPassword(_ value: String) async throws {
        switch mode {
        case .test:
            await MainActor.run {
                let registerFormRef = RegisterFormMockManager.get(idForMock)!
                registerFormRef.password = value
            }
        case .real:
            fatalError()
        }
    }
    
    public func getIssue() async throws -> Issue? {
        switch mode {
        case .test:
            await MainActor.run {
                let registerFormRef = RegisterFormMockManager.get(idForMock)!
                return registerFormRef.issue
            }
        case .real:
            fatalError()
        }
    }
    
    // MARK: action
    public func submit() async throws {
        switch mode {
        case .test:
            await MainActor.run {
                let registerFormRef = RegisterFormMockManager.get(idForMock)!
                registerFormRef.submit()
            }
        case .real:
            try await Auth.auth().createUser(withEmail: "", password: "")
            fatalError()
        }
    }
    
    
    // MARK: value
    public struct ID: Sendable, Hashable {
        public let value: UUID
        
        internal init(idForMock: RegisterFormMock.ID) {
            self.value = idForMock.value
        }
    }
}
