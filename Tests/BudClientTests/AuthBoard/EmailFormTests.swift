//
//  EmailFormTests.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Testing
import Foundation
import BudClient


// MARK: Tests
@Suite("EmailForm")
struct EmailFormTests {
    struct SetUpRegisterForm {
        let budClientRef: BudClient
        let emailFormRef: EmailForm
        init() async throws {
            self.budClientRef = await BudClient(mode: .test)
            self.emailFormRef = await getEmailForm(budClientRef)
        }
        
        @Test func setRegisterForm() async throws {
            // given
            try await #require(emailFormRef.registerForm == nil)
            
            // when
            await emailFormRef.setUpRegisterForm()
            
            // then
            await #expect(emailFormRef.registerForm != nil)
        }
        @Test func createRegisterForm() async throws {
            // given
            try await #require(emailFormRef.registerForm == nil)
            
            // when
            await emailFormRef.setUpRegisterForm()
            
            // then
            let registerForm = try #require(await emailFormRef.registerForm)
            await #expect(RegisterFormManager.get(registerForm) != nil)
        }
        @Test func whenRegisterFormAlreadyExists() async throws {
            // given
            try await #require(emailFormRef.registerForm == nil)
            
            await emailFormRef.setUpRegisterForm()
            let registerForm = try #require(await emailFormRef.registerForm)
            
            // when
            await emailFormRef.setUpRegisterForm()
            
            // then
            await #expect(emailFormRef.registerForm == registerForm)
        }
    }
}


// MARK: Helphers
internal func getEmailForm(_ budClientRef: BudClient) async -> EmailForm {
    let authBoardRef = await getAuthBoard(budClientRef)
    
    await authBoardRef.setUpEmailForm()
    let emailForm = await authBoardRef.emailForm!
    let emailFormRef = await EmailFormManager.get(emailForm)!
    return emailFormRef
}
