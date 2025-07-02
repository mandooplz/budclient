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
            await Server.run {
                mock.ref?.idToken = value
            }
        case .real(let object):
            await Server.run {
                object.ref?.idToken = value
            }
        }
    }
    package func setAccessToken(_ value: String) async {
        switch mode {
        case .test(let mock):
            await Server.run {
                mock.ref?.accessToken = value
            }
        case .real(let object):
            await Server.run {
                object.ref?.accessToken = value
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
    internal enum Mode: Sendable {
        case test(mock: GoogleRegisterFormMock.ID)
        case real(object: GoogleRegisterForm.ID)
    }
}
