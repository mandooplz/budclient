//
//  SystemBoardTests.swift
//  BudClient
//
//  Created by 김민우 on 7/7/25.
//
import Foundation
import Testing
import Tools
@testable import BudClient


@Suite("SystemBoard")
struct SystemBoardTests {
    struct CreateFirstSystem {
        let budClientRef: BudClient
        let systemBoardRef: SystemBoard
        init() async {
            self.budClientRef = await BudClient()
            self.systemBoardRef = await createAndGetSystemBoard(budClientRef)
        }
        
        @Test func whenSystemBoardIsDeleted() async throws {
            // given
            try await #require(systemBoardRef.id.isExist == true)
            
            // when
            await systemBoardRef.createFirstSystem {
                await systemBoardRef.delete()
            }
            
            // then
            let issue = try #require(await systemBoardRef.issue as? KnownIssue)
            #expect(issue.reason == "systemBoardIsDeleted")
        }
        
        @Test(.disabled()) func createSystemSourceInBudServer() async throws {
            
        }
    }
}

