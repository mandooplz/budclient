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
            await BudServer.run {
                mock.ref?.email = value
            }
        case .real(let object):
            await BudServer.run {
                object.ref?.email = value
            }
        }
    }
    package func setPassword(_ value: String) async {
        switch mode {
        case .test(let mock):
            await BudServer.run {
                mock.ref?.password = value
            }
        case .real(let object):
            await BudServer.run {
                object.ref?.password = value
            }
        }
    }
    
    
    // MARK: action
    package func submit() async {
        switch mode {
        case .test(let mock):
            await mock.ref?.submit()
        case .real(let object):
            await object.ref?.submit()
        }
    }
    package func remove() async {
        switch mode {
        case .test(let mock):
            await mock.ref?.remove()
        case .real(let object):
            await object.ref?.remove()
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
