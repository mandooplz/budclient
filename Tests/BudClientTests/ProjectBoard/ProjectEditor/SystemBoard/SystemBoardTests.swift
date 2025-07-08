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
@testable import BudServer


// MARK: Tests
@Suite("SystemBoard", .timeLimit(.minutes(1)))
struct SystemBoardTests {
    struct SetUp {
        let budClientRef: BudClient
        let systemBoardRef: SystemBoard
        init() async {
            self.budClientRef = await BudClient()
            self.systemBoardRef = await createAndGetSystemBoard(budClientRef)
        }
    }
    
    struct Subscribe {
        
    }
    
    struct Unsubscribe {
        
    }
    
    struct CreateFirstSystem {
        let budClientRef: BudClient
        let systemBoardRef: SystemBoard
        init() async {
            self.budClientRef = await BudClient()
            self.systemBoardRef = await createAndGetSystemBoard(budClientRef)
            
            await systemBoardRef.setUp()
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
        @Test func whenSystemAlreadyExist() async throws {
            // given
            let _ = await MainActor.run {
                systemBoardRef.models.insert(.init())
            }
            try await #require(systemBoardRef.issue == nil)
            
            // when
            await systemBoardRef.createFirstSystem()
            
            // then
            let issue = try #require(await systemBoardRef.issue as? KnownIssue)
            #expect(issue.reason == "systemAlreadyExist")
        }
        
        @Test func createSystemModel() async throws {
            // given
            try await #require(systemBoardRef.isModelsEmpty == true)
            
            await systemBoardRef.unsubscribe()
            
            // when
            await withCheckedContinuation { con in
                Task {
                    await systemBoardRef.setCallback {
                        con.resume()
                    }
                    await systemBoardRef.subscribe()
                    
                    await systemBoardRef.createFirstSystem()
                }
            }
            
            // then
            try await #require(systemBoardRef.models.count == 1)
            
            let systemModel = try #require(await systemBoardRef.models.first)
            await #expect(systemModel.isExist == true)
        }
        @Test func createSystemSource() async throws {
            // given
            let projectEditorRef = try #require(await systemBoardRef.config.parent.ref)
            let projectSourceLink = projectEditorRef.sourceLink
            
            try await #require(projectSourceLink.getSystemSources().isEmpty == true)
            
            // when
            await systemBoardRef.createFirstSystem()
            
            // then
            await #expect(projectSourceLink.getSystemSources().count == 1)
        }
    }
}



