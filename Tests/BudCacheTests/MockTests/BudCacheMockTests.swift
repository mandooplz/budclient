//
//  BudCacheMockTests.swift
//  BudClient
//
//  Created by 김민우 on 6/28/25.
//
import Testing
import Foundation
@testable import BudCache


// MARK: Tests
@Suite("BudCacheMock")
struct BudCacheMockTests {
    struct SignIn {
        let budCacheMockRef: BudCacheMock
        init() async {
            self.budCacheMockRef = await BudCacheMock()
        }
        
        @Test func whenEmailCredentialIsNil() async throws {
            // given
            try await #require(budCacheMockRef.emailCredential == nil)
            
            // when
            await budCacheMockRef.signIn()
            
            // then
            await #expect(budCacheMockRef.userId == nil)
        }
    }
}
