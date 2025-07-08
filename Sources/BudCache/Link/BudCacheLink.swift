//
//  BudCacheLink.swift
//  BudClient
//
//  Created by 김민우 on 6/28/25.
//
import Foundation
import Values
import FirebaseAuth
import BudServer


// MARK: Link
package struct BudCacheLink: Sendable {
    // MARK: core
    private let mode: SystemMode
    private let budCacheMockRef: BudCacheMock
    package init(mode: SystemMode, budCacheMockRef: BudCacheMock) {
        self.mode = mode
        self.budCacheMockRef = budCacheMockRef
    }
    
    
    // MARK: state
    package func getUser() async -> UserID? {
        switch mode {
        case .test:
            return await budCacheMockRef.user
        case .real:
            return Auth.auth().currentUser?.uid.toUserID()
        }
    }
    package func setUser(_ value: UserID) async {
        switch mode {
        case .test:
            await Server.run {
                budCacheMockRef.user = value
            }
        case .real:
            return
        }
    }
    package func resetUser() async throws {
        switch mode {
        case .test:
            await Server.run {
                budCacheMockRef.user = nil
            }
        case .real:
            await withThrowingTaskGroup { group in
                group.addTask {
                    try Auth.auth().signOut()
                }
            }
        }
    }
}
