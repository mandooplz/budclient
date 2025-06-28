//
//  GoogleRegisterFormMockTests.swift
//  BudClient
//
//  Created by 김민우 on 6/29/25.
//
import Foundation
import Testing
import Tools
@testable import BudServer


// MARK: Tests
@Suite("GoogleRegisterFormMock")
struct GoogleRegisterFormMockTests {
    struct FetchGoogleUserId {
        let accountHubRef: AccountHubMock
        let googleRegisterFormRef: GoogleRegisterFormMock
        init() async {
            self.accountHubRef = await AccountHubMock()
            self.googleRegisterFormRef = await getGoogleRegisterForm(accountHubRef)
        }
        
        @Test func whenIdTokenIsNil() async throws {
            // given
            await MainActor.run {
                googleRegisterFormRef.idToken = nil
            }
            
            // when
            await googleRegisterFormRef.fetchGoogleUserId()
            
            // then
            let issue = try #require(await googleRegisterFormRef.issue)
            #expect(issue.isKnown == true)
            #expect(issue.reason == "idTokenIsNil")
        }
        @Test func whenAccessTokenIsNil() async throws {
            // given
            await MainActor.run {
                googleRegisterFormRef.idToken = "sampleIdToken"
                googleRegisterFormRef.accessToken = nil
            }
            
            // when
            await googleRegisterFormRef.fetchGoogleUserId()
            
            // then
            let issue = try #require(await googleRegisterFormRef.issue)
            #expect(issue.isKnown == true)
            #expect(issue.reason == "accessTokenIsNil")
        }
        
        @Test func setGoogleUserId() async throws {
            // given
            await MainActor.run {
                googleRegisterFormRef.idToken = "sampleIdToken"
                googleRegisterFormRef.accessToken = "sampleAccessToken"
            }
            
            // when
            await googleRegisterFormRef.fetchGoogleUserId()
            
            // then
            try await #require(googleRegisterFormRef.issue == nil)
            await #expect(googleRegisterFormRef.googleUserId != nil)
        }
    }
    
    struct Submit {
        let accountHubRef: AccountHubMock
        let googleRegisterFormRef: GoogleRegisterFormMock
        init() async {
            self.accountHubRef = await AccountHubMock()
            self.googleRegisterFormRef = await getGoogleRegisterForm(accountHubRef)
        }
        
        @Test func whenGoogleUserIdIsNil() async throws {
            // given
            try await #require(googleRegisterFormRef.googleUserId == nil)
            
            // when
            await googleRegisterFormRef.submit()
            
            // then
            let issue = try #require(await googleRegisterFormRef.issue)
            #expect(issue.isKnown == true)
            #expect(issue.reason == "googleUserIdIsNil")
        }
        
        @Test func appendAccount() async throws {
            // given
            await MainActor.run {
                googleRegisterFormRef.idToken = Token.random().value
                googleRegisterFormRef.accessToken = Token.random().value
                googleRegisterFormRef.fetchGoogleUserId()
            }
            
            // when
            await googleRegisterFormRef.submit()
            
            // then
            try await #require(googleRegisterFormRef.issue == nil)
            
            let googleUserId = try #require(await googleRegisterFormRef.googleUserId)
            await #expect(accountHubRef.isExist(googleUserId: googleUserId) == true)
        }
        @Test func createAccount() async throws {
            // given
            await MainActor.run {
                googleRegisterFormRef.idToken = Token.random().value
                googleRegisterFormRef.accessToken = Token.random().value
                googleRegisterFormRef.fetchGoogleUserId()
            }
            
            // when
            await googleRegisterFormRef.submit()
            
            // then
            try await #require(googleRegisterFormRef.issue == nil)
            
            let googleUserId = try #require(await googleRegisterFormRef.googleUserId)
            let accountRef = await MainActor.run {
                accountHubRef.accounts.lazy
                    .compactMap { AccountMockManager.get($0) }
                    .first { $0.googleUserId == googleUserId }!
            }
            await #expect(AccountMockManager.get(accountRef.id) != nil)
            
        }
        @Test(.disabled()) func whenAccountAlreadyExists() async throws {
            // given
            
            // when
            
            // then
        }
    }
}


// MARK: Helpher
private func getGoogleRegisterForm(_ accountHubRef: AccountHubMock) async -> GoogleRegisterFormMock {
    let ticket = AccountHubMock.Ticket()
    
    await MainActor.run {
        accountHubRef.googleTickets.insert(ticket)
        accountHubRef.updateGoogleForms()
    }
    
    let googleRegisterForm = await accountHubRef.googleRegisterForms[ticket]!
    return await GoogleRegisterFormMockManager.get(googleRegisterForm)!
}
