//
//  BudClientTests.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Testing
import Foundation
@testable import BudClient


// MARK: Tests
@Suite("BudClient")
struct BudClientTests {
    struct SetUp {
        let budClientRef: BudClient
        init() async throws {
            self.budClientRef = await BudClient()
        }
        @Test func setAuthBoard() async throws {
            // given
            try await #require(budClientRef.authBoard == nil)
            
            // when
            await budClientRef.setUp()
            
            // then
            try await #require(budClientRef.issue == nil)
            await #expect(budClientRef.authBoard != nil)
        }
        @Test func setProjectBoard() async throws {
            // then
            try await #require(budClientRef.issue == nil)
            await #expect(budClientRef.projectBoard == nil)
        }
        @Test func setBudServerLink() async throws {
            // given
            try await #require(budClientRef.budServerLink == nil)
            
            // when
            await budClientRef.setUp()
            
            // then
            try await #require(budClientRef.issue == nil)
            await #expect(budClientRef.budServerLink != nil)
        }
        
        @Test func setAndCreateAuthBoard() async throws {
            // given
            try await #require(budClientRef.authBoard == nil)
            
            // when
            await budClientRef.setUp()
            
            // then
            try await #require(budClientRef.issue == nil)
            
            let authBoard = try #require(await budClientRef.authBoard)
            await #expect(authBoard.isExist == true)
        }
        @Test func whenAlreaySetUp() async throws {
            // given
            try await #require(budClientRef.authBoard == nil)
            
            await budClientRef.setUp()
            let authBoard = try #require(await budClientRef.authBoard)
            
            // when
            await budClientRef.setUp()
            
            // then
            try await #require(budClientRef.isIssueOccurred == true)
            let issue = try #require(await budClientRef.issue)
            #expect(issue.isKnown == true)
            #expect(issue.reason == "alreadySetUp")
            
            await #expect(budClientRef.authBoard == authBoard)
        }
        
        @Test func whenPlistPathIsWrong() async throws {
            // given
            let budClientForReal = await BudClient(plistPath: "wrongPath")
            
            // when
            await budClientForReal.setUp()
            
            // then
            try await #require(budClientForReal.isIssueOccurred == true)
            
            let issue = try #require(await budClientForReal.issue)
            #expect(issue.isKnown == true)
            #expect(issue.reason == "invalidPlistPath")
        }
    }
}

