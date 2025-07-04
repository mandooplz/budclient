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
    package func getUser() async -> UserID? {
        switch mode {
        case .test(let mockRef):
            return await mockRef.user
        case .real:
            return Auth.auth().currentUser?.uid.toUserID()
        }
    }
    package func setUser(_ value: UserID) async {
        switch mode {
        case .test(let mockRef):
            await MainActor.run {
                mockRef.user = value
            }
        case .real:
            return
        }
    }
    package func resetUser() async throws {
        switch mode {
        case .test(let mockRef):
            await MainActor.run {
                mockRef.user = nil
            }
        case .real:
            await withThrowingTaskGroup { group in
                group.addTask {
                    try Auth.auth().signOut()
                }
            }
        }
    }
    
    
    // MARK: value
    package enum Mode: Sendable {
        case test(mockRef: BudCacheMock)
        case real
    }
}
