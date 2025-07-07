//
//  GoogleRegisterFormLink.swift
//  BudClient
//
//  Created by 김민우 on 6/29/25.
//
import Foundation
import Tools
import FirebaseAuth
import BudServerMock
import BudServerLocal


// MARK: Link
package struct GoogleRegisterFormLink: Sendable {
    // MARK: core
    private nonisolated let mode: SystemMode
    private nonisolated let object: GoogleRegisterFormID
    private typealias TestManager = GoogleRegisterFormMockManager
    private typealias RealManager = GoogleRegisterFormManager
    internal init(mode: SystemMode, object: GoogleRegisterFormID) {
        self.mode = mode
        self.object = object
    }
    
    
    // MARK: state
    @Server
    package func setToken(_ token: GoogleToken) async {
        switch mode {
        case .test:
            TestManager.get(object)?.token = token
        case .real:
            RealManager.get(object)?.token = token
        }
    }
    
    
    // MARK: action
    package func submit() async {
        switch mode {
        case .test:
            await TestManager.get(object)?.submit()
        case .real:
            await RealManager.get(object)?.submit()
        }
    }
    package func remove() async {
        switch mode {
        case .test:
            await TestManager.get(object)?.remove()
        case .real:
            await RealManager.get(object)?.remove()
        }
    }
    
    
    // MARK: value
}
