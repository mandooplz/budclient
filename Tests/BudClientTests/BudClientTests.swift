//
//  BudClientTests.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Testing
import Foundation
import Values
@testable import BudClient
@testable import BudCache


// MARK: Tests
@Suite("BudClient")
struct BudClientTests {
    struct SetUp {
        let budClientRef: BudClient
        init() async throws {
            self.budClientRef = await BudClient()
        }
        
        @Test func setSignInForm() async throws {
            // given
            try await #require(budClientRef.signInForm == nil)
            
            // when
            await budClientRef.setUp()
            
            // then
            try await #require(budClientRef.issue == nil)
            await #expect(budClientRef.signInForm != nil)
        }
        @Test func createSignInForm() async throws {
            // given
            try await #require(budClientRef.signInForm == nil)
            
            // when
            await budClientRef.setUp()
            
            // then
            try await #require(budClientRef.issue == nil)
            
            let signInForm = try #require(await budClientRef.signInForm)
            await #expect(signInForm.isExist == true)
        }
        
        @Test func setProjectBoardNil() async throws {
            // given
            try await #require(budClientRef.projectBoard == nil)
            
            // when
            await budClientRef.setUp()
            
            // then
            try await #require(budClientRef.issue == nil)
            await #expect(budClientRef.projectBoard == nil)
        }
        @Test func setCommunityNil() async throws {
            // given
            try await #require(budClientRef.community == nil)
            
            // when
            await budClientRef.setUp()
            
            // then
            try await #require(budClientRef.issue == nil)
            await #expect(budClientRef.community == nil)
        }
        @Test func setUserNil() async throws {
            // given
            try await #require(budClientRef.user == nil)
            
            // when
            await budClientRef.setUp()
            
            // then
            try await #require(budClientRef.issue == nil)
            await #expect(budClientRef.user == nil)
        }
        
        @Test func whenAlreaySetUp() async throws {
            // given
            try await #require(budClientRef.signInForm == nil)
            
            await budClientRef.setUp()
            let signInForm = try #require(await budClientRef.signInForm)
            
            // when
            await budClientRef.setUp()
            
            // then
            try await #require(budClientRef.isIssueOccurred == true)
            
            let issue = try #require(await budClientRef.issue as? KnownIssue)
            #expect(issue.reason == "alreadySetUp")
            
            await #expect(budClientRef.signInForm == signInForm)
        }
    }
    
    struct SaveUserInCache {
        let budClientRef: BudClient
        init() async throws {
            self.budClientRef = await BudClient()
        }
        
        @Test func calledBeforeSetUp() async throws {
            // given
            try await #require(budClientRef.signInForm == nil)
            
            // when
            await budClientRef.saveUserInCache()
            
            // then
            let issue = try #require(await budClientRef.issue as? KnownIssue)
            #expect(issue.reason == "setUpRequired")
        }
        @Test func calledWhenUserIsNil() async throws {
            // given
            await budClientRef.setUp()
            
            try await #require(budClientRef.user == nil)
            
            // when
            await budClientRef.saveUserInCache()
            
            // then
            let issue = try #require(await budClientRef.issue as? KnownIssue)
            #expect(issue.reason == "signInRequired")
        }
        
        @Test func saveUserIDInBudCache() async throws {
            // given
            await budClientRef.setUp()
            
            let someUser = UserID()
            await MainActor.run {
                budClientRef.user = someUser
            }
            
            // when
            await budClientRef.saveUserInCache()
            
            try await #require(budClientRef.issue == nil)
            
            // then
            let userFromCache = try #require(await budClientRef.tempConfig?.budCache.ref?.getUser())
            #expect(userFromCache == someUser)
        }
    }
}


