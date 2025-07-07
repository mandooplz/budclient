//
//  GoogleRegisterFormMockTests.swift
//  BudClient
//
//  Created by 김민우 on 6/29/25.
//
import Foundation
import Testing
import Values
@testable import BudServerMock


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
        
        @Test func whenTokenIsNil() async throws {
            // given
            await Server.run {
                googleRegisterFormRef.token = nil
            }
            
            // when
            await googleRegisterFormRef.submit()
            
            // then
            let issue = try #require(await googleRegisterFormRef.issue as? KnownIssue)
            #expect(issue.reason == "tokenIsNil")
        }
        
        @Test func appendAccount() async throws {
            // given
            let googleToken = GoogleToken.random()
            await Server.run {
                googleRegisterFormRef.token = googleToken
            }
            
            // when
            await googleRegisterFormRef.submit()
            
            // then
            try await #require(googleRegisterFormRef.issue == nil)
            
            await #expect(accountHubRef.isExist(token: googleToken) == true)
        }
        @Test func createAccount() async throws {
            // given
            let googleToken = GoogleToken.random()
            await Server.run {
                googleRegisterFormRef.token = googleToken
            }
            
            // when
            await googleRegisterFormRef.submit()
            
            // then
            try await #require(googleRegisterFormRef.issue == nil)
            
            let accountRef = await Server.run {
                accountHubRef.accounts.lazy
                    .compactMap { $0.ref }
                    .first { $0.token == googleToken }
            }
            #expect(accountRef != nil)
            
        }
    }
}


// MARK: Helpher
fileprivate let manager = GoogleRegisterFormMockManager.self

private func getGoogleRegisterForm(_ accountHubRef: AccountHubMock) async -> GoogleRegisterFormMock {
    let ticket = CreateGoogleForm()
    
    await Server.run {
        accountHubRef.googleTickets.insert(ticket)
        accountHubRef.updateGoogleForms()
    }
    
    let googleRegisterForm = await accountHubRef.googleRegisterForms[ticket]!
    return await manager.get(googleRegisterForm)!
}
