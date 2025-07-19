//
//  GoogleFormTests.swift
//  BudClient
//
//  Created by 김민우 on 6/28/25.
//
import Testing
import Foundation
import Values
@testable import BudClient
@testable import BudCache


// MARK: Tests
@Suite("GoogleForm")
struct GoogleFormTests {
    struct FetchGoogleClientId {
        let budClientRef: BudClient
        let googleFormRef: GoogleForm
        init() async throws {
            self.budClientRef = await BudClient()
            self.googleFormRef = try await getGoogleForm(budClientRef)
        }
        
        @Test func whenGoogleFormIsDeleted() async throws {
            // given
            try await #require(googleFormRef.id.isExist == true)
            
            await googleFormRef.setCaptureHook {
                await googleFormRef.delete()
            }
            
            // when
            await googleFormRef.fetchGoogleClientId()
            
            // then
            let issue = try #require(await googleFormRef.issue as? KnownIssue)
            #expect(issue.reason == "googleFormIsDeleted")
        }
        
        @Test func updateGoogleClientId() async throws {
            // given
            try await #require(googleFormRef.googleClientId == nil)
            
            // when
            await googleFormRef.fetchGoogleClientId()
            
            // then
            try await #require(googleFormRef.issue == nil)
            await #expect(googleFormRef.googleClientId != nil)
        }
    }
    
    struct Submit {
        let budClientRef: BudClient
        let googleFormRef: GoogleForm
        init() async throws {
            self.budClientRef = await BudClient()
            self.googleFormRef = try await getGoogleForm(budClientRef)
        }
        
        @Test func whenGoogleFormIsDeletedBeforeCapture() async throws {
            // given
            try await #require(googleFormRef.id.isExist == true)
            
            await googleFormRef.setCaptureHook {
                await googleFormRef.delete()
            }
            
            // when
            await googleFormRef.submit()
            
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
            
            await googleFormRef.setMutateHook {
                await googleFormRef.delete()
            }
            
            // when
            await googleFormRef.submit()
            
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
            await googleFormRef.submit()
            
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
            await googleFormRef.submit()
            
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
            
            let signInForm = try #require(await budClientRef.signInForm)
            try await #require(signInForm.isExist == true)
            
            // when
            await googleFormRef.submit()
            
            // then
            await #expect(signInForm.isExist == false)
        }
        @Test func deleteSignUpForm() async throws {
            // given
            await MainActor.run {
                googleFormRef.idToken = Token.random().value
                googleFormRef.accessToken = Token.random().value
            }
            
            let signInFormRef = try #require(await budClientRef.signInForm?.ref)
            await signInFormRef.setUpSignUpForm()
            
            let signUpForm = try #require(await signInFormRef.signUpForm)
            try await #require(signUpForm.isExist == true)
            
            // when
            await googleFormRef.submit()
            
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
            await googleFormRef.submit()
            
            // then
            try await #require(googleFormRef.issue == nil)
            await #expect(googleFormRef.id.isExist == false)
        }
        
        @Test func createProjectBoard() async throws {
            // given
            await MainActor.run {
                googleFormRef.idToken = Token.random().value
                googleFormRef.accessToken = Token.random().value
            }
            
            try await #require(budClientRef.projectBoard == nil)
            
            // when
            await googleFormRef.submit()
            
            // then
            let projectBoard = try #require(await budClientRef.projectBoard)
            await #expect(projectBoard.isExist == true)
        }
        @Test func createProfile() async throws {
            // given
            await MainActor.run {
                googleFormRef.idToken = Token.random().value
                googleFormRef.accessToken = Token.random().value
            }
            
            try await #require(budClientRef.profile == nil)
            
            // when
            await googleFormRef.submit()
            
            // then
            let profileBoard = try #require(await budClientRef.profile)
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
            await googleFormRef.submit()
            
            // then
            let community = try #require(await budClientRef.community)
            await #expect(community.isExist == true)
        }
        
        @Test func setSignInFormNil_BudClient() async throws {
            // given
            try await #require(budClientRef.signInForm != nil)
            
            await MainActor.run {
                googleFormRef.idToken = Token.random().value
                googleFormRef.accessToken = Token.random().value
            }
            
            // when
            await googleFormRef.submit()
            
            // then
            try await #require(googleFormRef.issue == nil)
            
            await #expect(budClientRef.signInForm == nil)
        }
        @Test func setUser_BudClient() async throws {
            // given
            try await #require(budClientRef.user == nil)
            
            await MainActor.run {
                googleFormRef.idToken = Token.random().value
                googleFormRef.accessToken = Token.random().value
            }
            
            // when
            await googleFormRef.submit()
            
            // then
            try await #require(googleFormRef.issue == nil)
            
            await #expect(budClientRef.user != nil)
        }
        @Test func setIsUserSignedIn_BudClient() async throws {
            // given
            await MainActor.run {
                googleFormRef.idToken = Token.random().value
                googleFormRef.accessToken = Token.random().value
            }
            try await #require(budClientRef.isUserSignedIn == false)
            
            // when
            await googleFormRef.submit()
            
            // then
            await #expect(budClientRef.user != nil)
            await #expect(budClientRef.isUserSignedIn == true)
        }
    }
}


// MARK: Helphers
private func getGoogleForm(_ budClientRef: BudClient) async throws -> GoogleForm {
    // BudClient.setUp()
    await budClientRef.setUp()
    let signInFormRef = try #require(await budClientRef.signInForm?.ref)
    
    // SignInForm.setUpGoogleForm()
    await signInFormRef.setUpGoogleForm()
    let googleFormRef = try #require(await signInFormRef.googleForm?.ref)
    
    return googleFormRef
}
