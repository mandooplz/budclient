//
//  EmailFormTests.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Testing
import Foundation
import BudClient
import Tools


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
            try await #require(emailFormRef.signUpForm == nil)
            
            // when
            await emailFormRef.setUpRegisterForm()
            
            // then
            await #expect(emailFormRef.signUpForm != nil)
        }
        @Test func createRegisterForm() async throws {
            // given
            try await #require(emailFormRef.signUpForm == nil)
            
            // when
            await emailFormRef.setUpRegisterForm()
            
            // then
            let registerForm = try #require(await emailFormRef.signUpForm)
            await #expect(SignUpFormManager.get(registerForm) != nil)
        }
        @Test func whenRegisterFormAlreadyExists() async throws {
            // given
            try await #require(emailFormRef.signUpForm == nil)
            
            await emailFormRef.setUpRegisterForm()
            let registerForm = try #require(await emailFormRef.signUpForm)
            
            // when
            await emailFormRef.setUpRegisterForm()
            
            // then
            await #expect(emailFormRef.signUpForm == registerForm)
        }
    }
    
    struct SignIn {
        let budClientRef: BudClient
        let emailFormRef: EmailForm
        init() async throws {
            self.budClientRef = await BudClient(mode: .test)
            self.emailFormRef = await getEmailForm(budClientRef)
        }
        
        @Test func whenEmailIsNil() async throws {
            // given
            await MainActor.run {
                emailFormRef.email = nil
            }
            
            // when
            await emailFormRef.signIn()
            
            // then
            let issue = try #require(await emailFormRef.issue)
            #expect(issue.isKnown == true)
            #expect(issue.reason == "emailIsNil")
        }
        @Test func whenPasswordIsNil() async throws {
            await MainActor.run {
                emailFormRef.email = Email.random().value
                emailFormRef.password = nil
            }
            
            // when
            await emailFormRef.signIn()
            
            // then
            let issue = try #require(await emailFormRef.issue)
            #expect(issue.isKnown == true)
            #expect(issue.reason == "passwordIsNil")
        }
        
        @Test func updateCurrentUserInAuthBoard() async throws {
            // given
            let authBoardRef = await AuthBoardManager.get(budClientRef.authBoard!)
            try await #require(authBoardRef!.currentUser == nil)
            
            // when
            
            
            // then
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
private func signUpWithEmailForm(_ emailFormRef: EmailForm) async {
    
}
