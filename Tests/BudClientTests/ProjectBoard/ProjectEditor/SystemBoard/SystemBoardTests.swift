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
        
        @Test func whenSystemBoardIsDeleted() async throws {
            // given
            try await #require(systemBoardRef.id.isExist == true)
            
            // when
            await systemBoardRef.setUp {
                await systemBoardRef.delete()
            }
            
            // then
            let issue = try #require(await systemBoardRef.issue as? KnownIssue)
            #expect(issue.reason == "systemBoardIsDeleted")
        }
        @Test func createSystemUpdater() async throws {
            // given
            try await #require(systemBoardRef.updater == nil)
            
            // when
            await systemBoardRef.setUp()
            
            // then
            let updater = try #require(await systemBoardRef.updater)
            await #expect(updater.isExist == true)
        }
        @Test func whenAlreadySetUp() async throws {
            // given
            await systemBoardRef.setUp()
            
            let oldUpdater = try #require(await systemBoardRef.updater)
            
            // when
            await systemBoardRef.setUp()
            
            // then
            let newUpdater = try #require(await systemBoardRef.updater)
            #expect(newUpdater == oldUpdater)
            
            let issue = try #require(await systemBoardRef.issue as? KnownIssue)
            #expect(issue.reason == "alreadySetUp")
            
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
            
            let projectRef = try #require(await systemBoardRef.config.parent.ref)
            await projectRef.unsubscribe()
            
            // when
            await withCheckedContinuation { con in
                Task {
                    await projectRef.setCallback {
                        con.resume()
                    }
                    
                    await projectRef.subscribe()
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
            let projectRef = try #require(await systemBoardRef.config.parent.ref)
            let projectSourceLink = projectRef.sourceLink
            
            try await #require(projectSourceLink.getSystemSources().isEmpty == true)
            
            // when
            await systemBoardRef.createFirstSystem()
            
            // then
            await #expect(projectSourceLink.getSystemSources().count == 1)
        }
    }
}



