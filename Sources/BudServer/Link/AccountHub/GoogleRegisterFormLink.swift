//
//  GoogleRegisterFormLink.swift
//  BudClient
//
//  Created by 김민우 on 6/29/25.
//
import Foundation
import Tools
import FirebaseAuth


// MARK: Link
package struct GoogleRegisterFormLink: Sendable {
    // MARK: core
    private nonisolated let mode: Mode
    internal init(mode: Mode) {
        self.mode = mode
    }
    
    
    // MARK: state
    package func setIdToken(_ value: String) async {
        switch mode {
        case .test(let mock):
            await MainActor.run {
                let googleRegisterFormRef = GoogleRegisterFormMockManager.get(mock)!
                googleRegisterFormRef.idToken = value
            }
        case .real(let object):
            await Server.run {
                let googleRegisterFormRef = GoogleRegisterFormManager.get(object)!
                googleRegisterFormRef.idToken = value
            }
        }
    }
    package func setAccessToken(_ value: String) async {
        switch mode {
        case .test(let mock):
            await MainActor.run {
                let googleRegisterFormRef = GoogleRegisterFormMockManager.get(mock)!
                googleRegisterFormRef.accessToken = value
            }
        case .real(let object):
            await Server.run {
                let googleRegisterFormRef = GoogleRegisterFormManager.get(object)!
                googleRegisterFormRef.accessToken = value
            }
        }
    }
    
    
    // MARK: action
    package func submit() async {
        switch mode {
        case .test(let mock):
            let googleRegisterFormRef = await GoogleRegisterFormMockManager.get(mock)!
            await googleRegisterFormRef.submit()
        case .real(let object):
            let googleRegisterFormRef = await GoogleRegisterFormManager.get(object)!
            await googleRegisterFormRef.submit()
        }
    }
    package func remove() async {
        switch mode {
        case .test(let mock):
            let googleRegisterFormRef = await GoogleRegisterFormMockManager.get(mock)!
            await googleRegisterFormRef.remove()
        case .real(let object):
            let googleRegisterFormRef = await GoogleRegisterFormManager.get(object)!
            await googleRegisterFormRef.remove()
        }
    }
    
    
    // MARK: value
    internal enum Mode: Sendable {
        case test(mock: GoogleRegisterFormMock.ID)
        case real(object: GoogleRegisterForm.ID)
    }
}
