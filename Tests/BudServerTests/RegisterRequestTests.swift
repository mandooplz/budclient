//
//  RegisterRequestTests.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation
import Testing
import BudServer


// MARK: Tests
@Suite("RegisterRequest")
struct RegisterRequestTests {
    struct Submit {
        let registerRequestRef: RegisterRequest
        init() async {
            self.registerRequestRef = await .init()
        }
        @Test func createAccount() async throws {
            // given
            let testEmail = String(Int.random(in: 1...1000)) + "@" + "test.com"
            let testPassword = "12345678"
            
            await MainActor.run {
                registerRequestRef.email = testEmail
                registerRequestRef.password = testPassword
            }
            
            // when
            await registerRequestRef.submit()
            
            // then
            #expect(await AccountHub.isExist(email: testEmail,
                                       password: testPassword))
        }
        
        @Test func insertAccount() {
            
        }
    }
}
