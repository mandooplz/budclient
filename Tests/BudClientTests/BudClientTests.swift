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


// MARK: Tests
@Suite("BudClient")
struct BudClientTests {
    struct SetUp {
        let budClientRef: BudClient
        init() async throws {
            self.budClientRef = await BudClient()
        }
        @Test func setUpSignInForm() async throws {
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
        @Test func setProjectBoard() async throws {
            // then
            try await #require(budClientRef.issue == nil)
            await #expect(budClientRef.projectBoard == nil)
        }
        @Test func setCommunity() async throws {
            // then
            try await #require(budClientRef.issue == nil)
            await #expect(budClientRef.community == nil)
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
        @Test func calledBeforeSignIn() async throws {
            // given
            await budClientRef.setUp()
            
            try await #require(budClientRef.user == nil)
            
            // when
            await budClientRef.saveUserInCache()
            
            // then
            let issue = try #require(await budClientRef.issue as? KnownIssue)
            #expect(issue.reason == "signInRequired")
        }
    }
}


