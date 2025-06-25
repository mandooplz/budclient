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
            await emailFormRef.setUpSignUpForm()
            
            // then
            await #expect(emailFormRef.signUpForm != nil)
        }
        @Test func createRegisterForm() async throws {
            // given
            try await #require(emailFormRef.signUpForm == nil)
            
            // when
            await emailFormRef.setUpSignUpForm()
            
            // then
            let registerForm = try #require(await emailFormRef.signUpForm)
            await #expect(SignUpFormManager.get(registerForm) != nil)
        }
        @Test func whenRegisterFormAlreadyExists() async throws {
            // given
            try await #require(emailFormRef.signUpForm == nil)
            
            await emailFormRef.setUpSignUpForm()
            let registerForm = try #require(await emailFormRef.signUpForm)
            
            // when
            await emailFormRef.setUpSignUpForm()
            
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
            let testEmail = Email.random().value
            let testPassword = Password.random().value
            
            await signUpWithEmailForm(emailFormRef,
                                      email: testEmail,
                                      password: testPassword)
            
            // given
            let authBoard = await budClientRef.authBoard!
            let authBoardRef = await AuthBoardManager.get(authBoard)!
            await authBoardRef.signOut()
            try await #require(authBoardRef.currentUser == nil)
            try await #require(authBoardRef.emailForm != nil)
            
            let newEmailForm = await authBoardRef.emailForm!
            try #require(newEmailForm != emailFormRef.id)
            let newEmailFormRef = await EmailFormManager.get(newEmailForm)!
            
            await MainActor.run {
                newEmailFormRef.email = testEmail
                newEmailFormRef.password = testPassword
            }
            
            // when
            await newEmailFormRef.signIn()
            
            // then
            await #expect(newEmailFormRef.issue == nil)
            
            await #expect(authBoardRef.currentUser != nil)
        }
        @Test func setNilToEmailFormInAuthBoard() async throws {
            // given
            let testEmail = Email.random().value
            let testPassword = Password.random().value
            
            await signUpWithEmailForm(emailFormRef,
                                      email: testEmail,
                                      password: testPassword)
            
            // given
            let authBoard = await budClientRef.authBoard!
            let authBoardRef = await AuthBoardManager.get(authBoard)!
            await authBoardRef.signOut()
            try await #require(authBoardRef.currentUser == nil)
            try await #require(authBoardRef.emailForm != nil)
            
            let newEmailForm = await authBoardRef.emailForm!
            try #require(newEmailForm != emailFormRef.id)
            let newEmailFormRef = await EmailFormManager.get(newEmailForm)!
            
            await MainActor.run {
                newEmailFormRef.email = testEmail
                newEmailFormRef.password = testPassword
            }
            
            // when
            await newEmailFormRef.signIn()
            
            // then
            await #expect(newEmailFormRef.issue == nil)
            
            await #expect(authBoardRef.emailForm == nil)
        }
        @Test func deleteEmailFormWhenSignedIn() async throws {
            // given
            let testEmail = Email.random().value
            let testPassword = Password.random().value
            
            await signUpWithEmailForm(emailFormRef,
                                      email: testEmail,
                                      password: testPassword)
            
            // given
            let authBoard = await budClientRef.authBoard!
            let authBoardRef = await AuthBoardManager.get(authBoard)!
            await authBoardRef.signOut()
            try await #require(authBoardRef.currentUser == nil)
            try await #require(authBoardRef.emailForm != nil)
            
            let newEmailForm = await authBoardRef.emailForm!
            try #require(newEmailForm != emailFormRef.id)
            let newEmailFormRef = await EmailFormManager.get(newEmailForm)!
            
            await MainActor.run {
                newEmailFormRef.email = testEmail
                newEmailFormRef.password = testPassword
            }
            
            // when
            await newEmailFormRef.signIn()
            
            // then
            await #expect(newEmailFormRef.issue == nil)
            
            await #expect(EmailFormManager.get(newEmailForm) == nil)
        }
        
        @Test func updateAndCreateProjectBoard() async throws {
            // given
            let testEmail = Email.random().value
            let testPassword = Password.random().value
            
            await signUpWithEmailForm(emailFormRef,
                                      email: testEmail,
                                      password: testPassword)
            
            // given
            let authBoard = await budClientRef.authBoard!
            let authBoardRef = await AuthBoardManager.get(authBoard)!
            await authBoardRef.signOut()
            try await #require(authBoardRef.currentUser == nil)
            try await #require(authBoardRef.emailForm != nil)
            
            let newEmailForm = await authBoardRef.emailForm!
            try #require(newEmailForm != emailFormRef.id)
            let newEmailFormRef = await EmailFormManager.get(newEmailForm)!
            
            await MainActor.run {
                newEmailFormRef.email = testEmail
                newEmailFormRef.password = testPassword
            }
            
            // when
            await newEmailFormRef.signIn()
            
            // then
            let projectBoard = try #require(await budClientRef.projectBoard)
            await #expect(ProjectBoardManager.get(projectBoard) != nil)
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
private func signUpWithEmailForm(_ emailFormRef: EmailForm,
                                 email: String,
                                 password: String) async {
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
