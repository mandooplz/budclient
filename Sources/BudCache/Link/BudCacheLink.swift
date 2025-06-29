//
//  BudCacheLink.swift
//  BudClient
//
//  Created by 김민우 on 6/28/25.
//
import Foundation
import Tools
import FirebaseAuth
import BudServer


// MARK: Link
package struct BudCacheLink: Sendable {
    // MARK: core
    private let mode: Mode
    package init(mode: Mode) {
        self.mode = mode
    }
    
    
    // MARK: state
    package func getUserId() async -> String? {
        switch mode {
        case .test(let mockRef):
            return await mockRef.userId
        case .real:
            return Auth.auth().currentUser?.uid
        }
    }
    package func setUserId(_ value: String) async {
        switch mode {
        case .test(let mockRef):
            await MainActor.run {
                mockRef.userId = value
            }
        case .real:
            return
        }
    }
    
    
    // MARK: value
    package enum Mode: Sendable {
        case test(mockRef: BudCacheMock)
        case real
    }
}
