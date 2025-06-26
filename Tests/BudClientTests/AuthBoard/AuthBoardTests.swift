//
//  AuthBoardTests.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation
import Testing
import BudClient
import Tools


// MARK: Tests
@Suite("AuthBoard")
struct AuthBoardTests {
    struct SetUpEmailForm {
        let budClientRef: BudClient
        let authBoardRef: AuthBoard
        init() async {
            self.budClientRef = await BudClient(mode: .test)
            self.authBoardRef = await getAuthBoard(self.budClientRef)
        }
        
        @Test func setEmailForm() async throws {
            // given
            try await #require(authBoardRef.emailForm == nil)
            
            // when
            await authBoardRef.setUpEmailForm()
            
            // then
            try await #require(authBoardRef.emailForm != nil)
        }
        @Test func createEmailForm() async throws {
            // given
            try await #require(authBoardRef.emailForm == nil)
            
            // when
            await authBoardRef.setUpEmailForm()
            
            // then
            let emailForm = try #require(await authBoardRef.emailForm)
            await #expect(EmailFormManager.get(emailForm) != nil)
        }
        
        @Test func whenAlreadySetUp() async throws {
            // given
            try await #require(authBoardRef.emailForm == nil)
            
            await authBoardRef.setUpEmailForm()
            let emailForm = try #require(await authBoardRef.emailForm)
            
            // when
            await authBoardRef.setUpEmailForm()
            
            // then
            await #expect(authBoardRef.emailForm == emailForm)
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
    await authBoardRef.setUpEmailForm()
    
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
