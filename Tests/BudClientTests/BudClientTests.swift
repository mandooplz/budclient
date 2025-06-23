//
//  BudClientTests.swift
//  BudClient
//
//  Created by 김민우 on 6/23/25.
//
import Testing
import Foundation
import BudClient


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
            await #expect(budClientRef.authBoard != nil)
        }
        @Test func createAuthBoard() async throws {
            // given
            try await #require(budClientRef.authBoard == nil)
            
            // when
            await budClientRef.setUp()
            
            // then
            let authBoard = try #require(await budClientRef.authBoard)
            await #expect(AuthBoardManager.get(authBoard) != nil)
        }
        @Test func whenAlreaySetUp() async throws {
            // given
            try await #require(budClientRef.authBoard == nil)
            
            await budClientRef.setUp()
            let authBoard = try #require(await budClientRef.authBoard)
            
            // when
            await budClientRef.setUp()
            
            // then
            await #expect(budClientRef.authBoard == authBoard)
        }
    }
}

