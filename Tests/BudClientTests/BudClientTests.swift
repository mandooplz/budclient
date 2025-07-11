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
        @Test func setCommunity() async throws {
            // then
            try await #require(budClientRef.issue == nil)
            await #expect(budClientRef.community == nil)
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
            let issue = try #require(await budClientRef.issue as? KnownIssue)
            #expect(issue.reason == "alreadySetUp")
            
            await #expect(budClientRef.authBoard == authBoard)
        }
    }
}

