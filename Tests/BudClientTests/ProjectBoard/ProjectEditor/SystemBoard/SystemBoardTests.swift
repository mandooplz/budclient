//
//  SystemBoardTests.swift
//  BudClient
//
//  Created by 김민우 on 7/7/25.
//
import Foundation
import Testing
import Values
@testable import BudClient


// MARK: Tests
@Suite("SystemBoard")
struct SystemBoardTests {
    struct Subscribe {
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
            await systemBoardRef.subscribe {
                await systemBoardRef.delete()
            }
            
            // then
            let issue = try #require(await systemBoardRef.issue as? KnownIssue)
            #expect(issue.reason == "systemBoardIsDeleted")
        }
    }
    
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
        
        @Test func createSystemSource() async throws {
            // given
            
        }
        
        @Test(.disabled()) func createSystemModel() async throws {
            // given
            try await #require(systemBoardRef.isModelsEmpty == true)
            
            // when
            await systemBoardRef.createFirstSystem()
            
            // then
            try await #require(systemBoardRef.models.count == 1)
            
            let systemModel = try #require(await systemBoardRef.models.first)
            await #expect(systemModel.isExist == true)
        }
    }
    
    
    struct UnSubscribe {
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
            await systemBoardRef.unsubscribe {
                await systemBoardRef.delete()
            }
            
            // then
            let issue = try #require(await systemBoardRef.issue as? KnownIssue)
            #expect(issue.reason == "systemBoardIsDeleted")
        }
    }
}



