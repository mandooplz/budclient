//
//  AuthBoardTests.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Foundation
import Testing
import Values
@testable import BudClient


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
        
        @Test func whenAuthBoardIsDeletedBeforMutate() async throws {
            // given
            try await #require(authBoardRef.id.isExist == true)
                
            // when
            await authBoardRef.setUpForms {
                await authBoardRef.delete()
            }
            
            // then
            let issue = try #require(await authBoardRef.issue as? KnownIssue)
            #expect(issue.reason == "authBoardIsDeleted")
            
            await #expect(authBoardRef.signInForm == nil)
            await #expect(authBoardRef.googleForm == nil)
        }
        
        @Test func setSignInForm() async throws {
            // given
            try await #require(authBoardRef.signInForm == nil)
            
            // when
            await authBoardRef.setUpForms()
            
            // then
            try await #require(authBoardRef.signInForm != nil)
        }
        @Test func createSignInForm() async throws {
            // given
            try await #require(authBoardRef.signInForm == nil)
            
            // when
            await authBoardRef.setUpForms()
            
            // then
            let emailForm = try #require(await authBoardRef.signInForm)
            await #expect(emailForm.isExist == true)
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
            await #expect(googleForm.isExist == true)
        }
        
        @Test func whenFormsAlreadySetUp() async throws {
            // given
            try await #require(authBoardRef.signInForm == nil)
            try await #require(authBoardRef.googleForm == nil)
            
            await authBoardRef.setUpForms()
            
            let emailForm = try #require(await authBoardRef.signInForm)
            let googleForm = try #require(await authBoardRef.googleForm)
            
            // when
            await authBoardRef.setUpForms()
            
            // then
            await #expect(authBoardRef.signInForm == emailForm)
            await #expect(authBoardRef.googleForm == googleForm)
        }
    }
}


// MARK: Helphers
func getAuthBoard(_ budClientRef: BudClient) async -> AuthBoard {
    try! await #require(budClientRef.authBoard == nil)
    
    await budClientRef.setUp()
    try! await #require(budClientRef.issue == nil)
    return await budClientRef.authBoard!.ref!
}
private func signUpWithEmailForm(_ authBoardRef: AuthBoard,
                                 email: String,
                                 password: String) async {
    await authBoardRef.setUpForms()
    
    let emailForm = try! #require(await authBoardRef.signInForm)
    let emailFormRef = try! #require(await emailForm.ref)
    
    await emailFormRef.setUpSignUpForm()
    
    let signUpForm = await emailFormRef.signUpForm!
    let signUpFormRef = await signUpForm.ref!
    
    await MainActor.run {
        signUpFormRef.email = email
        signUpFormRef.password = password
        signUpFormRef.passwordCheck = password
    }
    
    await signUpFormRef.signUp()
    await signUpFormRef.remove()
}
