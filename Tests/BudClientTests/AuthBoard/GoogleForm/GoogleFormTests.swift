//
//  GoogleFormTests.swift
//  BudClient
//
//  Created by 김민우 on 6/28/25.
//
import Testing
import Foundation
import Tools
@testable import BudClient


// MARK: Tests
@Suite("GoogleForm")
struct GoogleFormTests {
    struct SignIn {
        let budClientRef: BudClient
        let authBoardRef: AuthBoard
        let googleFormRef: GoogleForm
        init() async {
            self.budClientRef = await BudClient()
            self.googleFormRef = await getGoogleForm(budClientRef)
            self.authBoardRef = await googleFormRef.authBoard.ref!
        }
        
        @Test func whenGoogleFormIsDeletedBeforeCapture() async throws {
            // given
            try await #require(googleFormRef.id.isExist == true)
            
            // when
            await googleFormRef.signIn {
                await googleFormRef.delete()
            } mutateHook: {
                
            }
            
            // then
            await #expect(googleFormRef.issue == nil)
            await #expect(budClientRef.isUserSignedIn == false)
        }
        @Test func whenGoogleFormIsDeletedBeforeMutate() async throws {
            // given
            try await #require(googleFormRef.id.isExist == true)
            
            await MainActor.run {
                googleFormRef.idToken = Token.random().value
                googleFormRef.accessToken = Token.random().value
            }
            
            // when
            await googleFormRef.signIn {
                
            } mutateHook: {
                await googleFormRef.delete()
            }
            
            // then
            await #expect(googleFormRef.issue == nil)
            await #expect(budClientRef.isUserSignedIn == false)
        }
        
        @Test func whenIdTokenIsNil() async throws {
            // given
            await MainActor.run {
                googleFormRef.idToken = nil
            }
            
            // when
            await googleFormRef.signIn()
            
            // then
            let issue = try #require(await googleFormRef.issue)
            #expect(issue.isKnown == true)
            #expect(issue.reason == "idTokenIsNil")
        }
        @Test func whenAccessTokenIsNil() async throws {
            // given
            await MainActor.run {
                googleFormRef.idToken = Token.random().value
                googleFormRef.accessToken = nil
            }
            
            // when
            await googleFormRef.signIn()
            
            // then
            let issue = try #require(await googleFormRef.issue)
            #expect(issue.isKnown == true)
            #expect(issue.reason == "accessTokenIsNil")
        }
        
        @Test func deleteSignInForm() async throws {
            // given
            await MainActor.run {
                googleFormRef.idToken = Token.random().value
                googleFormRef.accessToken = Token.random().value
            }
            
            let signInForm = try #require(await authBoardRef.signInForm)
            try await #require(signInForm.isExist == true)
            
            // when
            await googleFormRef.signIn()
            
            // then
            await #expect(signInForm.isExist == false)
        }
        @Test func deleteSignUpForm() async throws {
            // given
            await MainActor.run {
                googleFormRef.idToken = Token.random().value
                googleFormRef.accessToken = Token.random().value
            }
            
            let signInFormRef = try #require(await authBoardRef.signInForm?.ref)
            await signInFormRef.setUpSignUpForm()
            
            let signUpForm = try #require(await signInFormRef.signUpForm)
            try await #require(signUpForm.isExist == true)
            
            // when
            await googleFormRef.signIn()
            
            // then
            await #expect(signUpForm.isExist == false)
        }
        @Test func deleteGoogleForm() async throws {
            // given
            await MainActor.run {
                googleFormRef.idToken = Token.random().value
                googleFormRef.accessToken = Token.random().value
            }
            
            // when
            await googleFormRef.signIn()
            
            // then
            try await #require(googleFormRef.issue == nil)
            await #expect(googleFormRef.id.isExist == false)
        }
        @Test func deleteAuthBoard() async throws {
            // given
            await MainActor.run {
                googleFormRef.idToken = Token.random().value
                googleFormRef.accessToken = Token.random().value
            }
            
            try await #require(authBoardRef.id.isExist == true)
            
            // when
            await googleFormRef.signIn()
            
            // then
            await #expect(authBoardRef.id.isExist == false)
        }
        
        @Test func createProjectBoard() async throws {
            // given
            await MainActor.run {
                googleFormRef.idToken = Token.random().value
                googleFormRef.accessToken = Token.random().value
            }
            
            try await #require(budClientRef.projectBoard == nil)
            
            // when
            await googleFormRef.signIn()
            
            // then
            let projectBoard = try #require(await budClientRef.projectBoard)
            await #expect(projectBoard.isExist == true)
        }
        @Test func createProfileBoard() async throws {
            // given
            await MainActor.run {
                googleFormRef.idToken = Token.random().value
                googleFormRef.accessToken = Token.random().value
            }
            
            try await #require(budClientRef.profileBoard == nil)
            
            // when
            await googleFormRef.signIn()
            
            // then
            let profileBoard = try #require(await budClientRef.profileBoard)
            await #expect(profileBoard.isExist == true)
        }
        @Test func setIsUserSignedIn() async throws {
            // given
            await MainActor.run {
                googleFormRef.idToken = Token.random().value
                googleFormRef.accessToken = Token.random().value
            }
            try await #require(budClientRef.isUserSignedIn == false)
            
            // when
            await googleFormRef.signIn()
            
            // then
            await #expect(budClientRef.isUserSignedIn == true)
        }
        
        @Test func setCredentialInBudCache() async throws {
            // 핵심은 userId을 저장한다는 사실 아닐까? 
        }
    }
}


// MARK: Helphers
private func getGoogleForm(_ budClientRef: BudClient) async -> GoogleForm {
    await budClientRef.setUp()
    
    let authBoard = await budClientRef.authBoard!
    let authBoardRef = await authBoard.ref!
    
    await authBoardRef.setUpForms()
    
    let googleForm = await authBoardRef.googleForm!
    let googleFormRef = await googleForm.ref!
    
    return googleFormRef
}
