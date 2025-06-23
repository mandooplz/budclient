//
//  SignUpFormTests.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation
import Testing
import Tools
import BudClient


// MARK: Tests
@Suite("SignUpForm")
struct SignUpFormTests {
    struct SignUp {
        let budClientRef: BudClient
        let signUpFormRef: SignUpForm
        init() async {
            self.budClientRef = await BudClient(mode: .test)
            self.signUpFormRef = await getSignUpForm(budClientRef)
        }
        
        @Test func failsWhenEmailIsNil() async throws {
            // given
            await MainActor.run {
                signUpFormRef.email = nil
            }
            
            // when
            await signUpFormRef.signUp()
            
            // then
            let issue = try #require(await signUpFormRef.issue)
            #expect(issue.isKnown == true)
            #expect(issue.reason == "emailIsNil")
        }
        @Test func failsWhenPasswordIsNil() async throws {
            // given
            await MainActor.run {
                signUpFormRef.email = Email.random().value
                signUpFormRef.password = nil
            }
            
            // when
            await signUpFormRef.signUp()
            
            // then
            let issue = try #require(await signUpFormRef.issue)
            #expect(issue.isKnown == true)
            #expect(issue.reason == "passwordIsNil")
        }
        @Test func failsWhenPasswordsDoNotMatch() async throws {
            // given
            await MainActor.run {
                signUpFormRef.email = Email.random().value
                signUpFormRef.password = Password.random().value
                signUpFormRef.passwordCheck = Password.random().value
            }
            
            // when
            await signUpFormRef.signUp()
            
            // then
            let issue = try #require(await signUpFormRef.issue)
            #expect(issue.isKnown == true)
            #expect(issue.reason == "passwordsDoNotMatch")
        }
        
        @Test func toggleIsConsumedWhenSuccess() async throws {
            // given
            let testEmail = Email.random().value
            let testPassword = Password.random().value
            await MainActor.run {
                signUpFormRef.email = testEmail
                signUpFormRef.password = testPassword
                signUpFormRef.passwordCheck = testPassword
            }
            
            // when
            await signUpFormRef.signUp()
            
            // then
            try await #require(signUpFormRef.issue == nil)
            await #expect(signUpFormRef.isConsumed == true)
        }
        @Test func deleteSignUpFormWhenSuccess() async throws {
            // given
            let testEmail = Email.random().value
            let testPassword = Password.random().value
            await MainActor.run {
                signUpFormRef.email = testEmail
                signUpFormRef.password = testPassword
                signUpFormRef.passwordCheck = testPassword
            }
            
            // when
            await signUpFormRef.signUp()
            
            // then
            try await #require(signUpFormRef.issue == nil)
            await #expect(SignUpFormManager.get(signUpFormRef.id) == nil)
        }
        @Test func deleteEmailFormWhenSuccess() async throws {
            // given
            let testEmail = Email.random().value
            let testPassword = Password.random().value
            await MainActor.run {
                signUpFormRef.email = testEmail
                signUpFormRef.password = testPassword
                signUpFormRef.passwordCheck = testPassword
            }
            
            let emailForm = signUpFormRef.emailForm
            
            // when
            await signUpFormRef.signUp()
            
            // then
            try await #require(signUpFormRef.issue == nil)
            await #expect(EmailFormManager.get(emailForm) == nil)
        }
        @Test func setCurrentUserInAuthBoard() async throws {
            // given
            let testEmail = Email.random().value
            let testPassword = Password.random().value
            await MainActor.run {
                signUpFormRef.email = testEmail
                signUpFormRef.password = testPassword
                signUpFormRef.passwordCheck = testPassword
            }
            
            let authBoard = await budClientRef.authBoard!
            let authBoardRef = await AuthBoardManager.get(authBoard)!
            
            // when
            await signUpFormRef.signUp()
            
            // then
            try await #require(signUpFormRef.issue == nil)
            await #expect(authBoardRef.currentUser != nil)
        }
        @Test func setNilToEmailFormInAuthBoard() async throws {
            // given
            let testEmail = Email.random().value
            let testPassword = Password.random().value
            await MainActor.run {
                signUpFormRef.email = testEmail
                signUpFormRef.password = testPassword
                signUpFormRef.passwordCheck = testPassword
            }
            
            let authBoard = await budClientRef.authBoard!
            let authBoardRef = await AuthBoardManager.get(authBoard)!
            
            // when
            await signUpFormRef.signUp()
            
            // then
            try await #require(signUpFormRef.issue == nil)
            await #expect(authBoardRef.emailForm == nil)
        }
    }
}


// MARK: Helphers
internal func getSignUpForm(_ budClientRef: BudClient) async -> SignUpForm {
    let emailForm = await getEmailForm(budClientRef)
    
    await emailForm.setUpRegisterForm()
    let signUpForm = try! #require(await emailForm.signUpForm)
    let signUpFormRef = await SignUpFormManager.get(signUpForm)!
    return signUpFormRef
}
