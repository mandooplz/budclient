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
    struct Submit {
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
            await googleRegisterFormRef.submit()
            
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
            await googleRegisterFormRef.submit()
            
            // then
            let issue = try #require(await googleRegisterFormRef.issue)
            #expect(issue.isKnown == true)
            #expect(issue.reason == "accessTokenIsNil")
        }
        
        @Test func appendAccount() async throws {
            // given
            let idToken = Token.random().value
            let accessToken = Token.random().value
            await MainActor.run {
                googleRegisterFormRef.idToken = idToken
                googleRegisterFormRef.accessToken = accessToken
            }
            
            // when
            await googleRegisterFormRef.submit()
            
            // then
            try await #require(googleRegisterFormRef.issue == nil)
            
            await #expect(accountHubRef.isExist(idToken: idToken,
                                                accessToken: accessToken) == true)
        }
        @Test func createAccount() async throws {
            // given
            let idToken = Token.random().value
            let accessToken = Token.random().value
            await MainActor.run {
                googleRegisterFormRef.idToken = idToken
                googleRegisterFormRef.accessToken = accessToken
            }
            
            // when
            await googleRegisterFormRef.submit()
            
            // then
            try await #require(googleRegisterFormRef.issue == nil)
            
            let accountRef = await MainActor.run {
                accountHubRef.accounts.lazy
                    .compactMap { AccountMockManager.get($0) }
                    .first { $0.idToken == idToken && $0.accessToken == accessToken }
            }
            #expect(accountRef != nil)
            
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
