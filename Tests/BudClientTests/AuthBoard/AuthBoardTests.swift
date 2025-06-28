//
//  AuthBoardTests.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation
import Testing
@testable import BudClient
import Tools


// MARK: Tests
@Suite("AuthBoard")
struct AuthBoardTests {
    struct SetUpForms {
        let budClientRef: BudClient
        let authBoardRef: AuthBoard
        init() async {
            self.budClientRef = await BudClient()
            self.authBoardRef = await getAuthBoard(self.budClientRef)
        }
        
        @Test func setEmailForm() async throws {
            // given
            try await #require(authBoardRef.emailForm == nil)
            
            // when
            await authBoardRef.setUpForms()
            
            // then
            try await #require(authBoardRef.emailForm != nil)
        }
        @Test func createEmailForm() async throws {
            // given
            try await #require(authBoardRef.emailForm == nil)
            
            // when
            await authBoardRef.setUpForms()
            
            // then
            let emailForm = try #require(await authBoardRef.emailForm)
            await #expect(EmailFormManager.get(emailForm) != nil)
        }
        
        @Test func setGoogleForm() async throws {
            // given
            try await #require(authBoardRef.googleForm == nil)
            
            // when
            await authBoardRef.setUpForms()
            
            // then
            await #expect(authBoardRef.googleForm != nil)
        }
        @Test func createGoogleForm() async throws {
            // given
            try await #require(authBoardRef.googleForm == nil)
            
            // when
            await authBoardRef.setUpForms()
            
            // then
            let googleForm = try #require(await authBoardRef.googleForm)
            await #expect(GoogleFormManager.get(googleForm) != nil)
        }
        
        @Test func whenFormsAlreadySetUp() async throws {
            // given
            try await #require(authBoardRef.emailForm == nil)
            try await #require(authBoardRef.googleForm == nil)
            
            await authBoardRef.setUpForms()
            
            let emailForm = try #require(await authBoardRef.emailForm)
            let googleForm = try #require(await authBoardRef.googleForm)
            
            // when
            await authBoardRef.setUpForms()
            
            // then
            await #expect(authBoardRef.emailForm == emailForm)
            await #expect(authBoardRef.googleForm == googleForm)
        }
    }
}


// MARK: Helphers
func getAuthBoard(_ budClientRef: BudClient) async -> AuthBoard {
    try! await #require(budClientRef.authBoard == nil)
    
    await budClientRef.setUp()
    
    let authBoard = await budClientRef.authBoard!
    let authBoardRef = await AuthBoardManager.get(authBoard)!
    return authBoardRef
}
private func signUpWithEmailForm(_ authBoardRef: AuthBoard,
                                 email: String,
                                 password: String) async {
    await authBoardRef.setUpForms()
    
    let emailForm = try! #require(await authBoardRef.emailForm)
    let emailFormRef = try! #require(await EmailFormManager.get(emailForm))
    
    await emailFormRef.setUpSignUpForm()
    
    let signUpForm = await emailFormRef.signUpForm!
    let signUpFormRef = await SignUpFormManager.get(signUpForm)!
    
    await MainActor.run {
        signUpFormRef.email = email
        signUpFormRef.password = password
        signUpFormRef.passwordCheck = password
    }
    
    await signUpFormRef.signUp()
    await signUpFormRef.remove()
}
