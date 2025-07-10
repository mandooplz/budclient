//
//  RegisterFormLink.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation
import Values
import FirebaseAuth


// MARK: Link
package struct EmailRegisterFormLink: Sendable {
    // MARK: core
    private nonisolated let mode: SystemMode
    private nonisolated let object: EmailRegisterFormID
    private typealias TestManager = EmailRegisterFormMockManager
    private typealias RealManager = EmailRegisterFormManager
    internal init(mode: SystemMode, object: EmailRegisterFormID) {
        self.mode = mode
        self.object = object
    }
    
    // MARK: state
    @Server package func setEmail(_ value: String) async {
        switch mode {
        case .test:
            TestManager.get(object)?.email = value
        case .real:
            RealManager.get(object)?.email = value
        }
    }
    @Server package func setPassword(_ value: String) async {
        switch mode {
        case .test:
            TestManager.get(object)?.password = value
        case .real:
            RealManager.get(object)?.password = value
        }
    }
    
    
    // MARK: action
    @Server package func submit() async {
        switch mode {
        case .test:
            TestManager.get(object)?.submit()
        case .real:
            await RealManager.get(object)?.submit()
        }
    }
    @Server package func remove() async {
        switch mode {
        case .test:
            TestManager.get(object)?.remove()
        case .real:
            await RealManager.get(object)?.remove()
        }
    }
}
