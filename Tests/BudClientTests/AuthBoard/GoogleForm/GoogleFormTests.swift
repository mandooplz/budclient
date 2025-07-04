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
@testable import BudCache


// MARK: Tests
@Suite("GoogleForm")
struct GoogleFormTests {
    struct SignUpAndSignIn {
        let budClientRef: BudClient
        let authBoardRef: AuthBoard
        let googleFormRef: GoogleForm
        init() async {
            self.budClientRef = await BudClient()
            self.googleFormRef = await getGoogleForm(budClientRef)
            self.authBoardRef = await googleFormRef.tempConfig.parent.ref!
        }
        
        @Test func whenGoogleFormIsDeletedBeforeCapture() async throws {
            // given
            try await #require(googleFormRef.id.isExist == true)
            
            // when
            await googleFormRef.signUpAndSignIn {
                await googleFormRef.delete()
            } mutateHook: {
                
            }
            
            // then
            let issue = try #require(await googleFormRef.issue as? KnownIssue)
            #expect(issue.reason == "googleFormIsDeleted")
            
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
            await googleFormRef.signUpAndSignIn {
                
            } mutateHook: {
                await googleFormRef.delete()
            }
            
            // then
            let issue = try #require(await googleFormRef.issue as? KnownIssue)
            #expect(issue.reason == "googleFormIsDeleted")
            
            await #expect(budClientRef.isUserSignedIn == false)
        }
        
        @Test func whenIdTokenIsNil() async throws {
            // given
            await MainActor.run {
                googleFormRef.idToken = nil
            }
            
            // when
            await googleFormRef.signUpAndSignIn()
            
            // then
            let issue = try #require(await googleFormRef.issue as? KnownIssue)
            #expect(issue.reason == "idTokenIsNil")
        }
        @Test func whenAccessTokenIsNil() async throws {
            // given
            await MainActor.run {
                googleFormRef.idToken = Token.random().value
                googleFormRef.accessToken = nil
            }
            
            // when
            await googleFormRef.signUpAndSignIn()
            
            // then
            let issue = try #require(await googleFormRef.issue as? KnownIssue)
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
            await googleFormRef.signUpAndSignIn()
            
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
            await googleFormRef.signUpAndSignIn()
            
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
            await googleFormRef.signUpAndSignIn()
            
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
            await googleFormRef.signUpAndSignIn()
            
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
            await googleFormRef.signUpAndSignIn()
            
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
            await googleFormRef.signUpAndSignIn()
            
            // then
            let profileBoard = try #require(await budClientRef.profileBoard)
            await #expect(profileBoard.isExist == true)
        }
        @Test func createCommunity() async throws {
            // given
            await MainActor.run {
                googleFormRef.idToken = Token.random().value
                googleFormRef.accessToken = Token.random().value
            }
            
            try await #require(budClientRef.community == nil)
            
            // when
            await googleFormRef.signUpAndSignIn()
            
            // then
            let community = try #require(await budClientRef.community)
            await #expect(community.isExist == true)
        }
        @Test func setIsUserSignedIn() async throws {
            // given
            await MainActor.run {
                googleFormRef.idToken = Token.random().value
                googleFormRef.accessToken = Token.random().value
            }
            try await #require(budClientRef.isUserSignedIn == false)
            
            // when
            await googleFormRef.signUpAndSignIn()
            
            // then
            await #expect(budClientRef.isUserSignedIn == true)
        }
        
        @Test func setUserIdInBudCache() async throws {
            // given
            let budCacheLink = budClientRef.budCacheLink
            try await #require(budCacheLink.getUser() == nil)
            
            await MainActor.run {
                googleFormRef.idToken = Token.random().value
                googleFormRef.accessToken = Token.random().value
            }
            
            // when
            await googleFormRef.signUpAndSignIn()
            
            // then
            await #expect(budCacheLink.getUser() != nil)
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
