//
//  SystemModelTests.swift
//  BudClient
//
//  Created by 김민우 on 7/8/25.
//
import Foundation
import Testing
import Values
@testable import BudClient


// MARK: Tests
@Suite("SystemModel", .timeLimit(.minutes(1)))
struct SystemModelTests {
    struct SetUp {
        let budClientRef: BudClient
        let systemModelRef: SystemModel
        init() async {
            self.budClientRef = await BudClient()
            self.systemModelRef = await getSystemModel(budClientRef)
        }
        
        @Test func whenSystemModelIsDeleted() async throws {
            // given
            try await #require(systemModelRef.id.isExist == true)
            
            // when
            await systemModelRef.setUp {
                await systemModelRef.delete()
            }
            
            // then
            let issue = try #require(await systemModelRef.issue as? KnownIssue)
            #expect(issue.reason == "systemModelIsDeleted")
        }
        @Test func createSystemUpdater() async throws {
            // given
            try await #require(systemModelRef.updater == nil)
            
            // when
            await systemModelRef.setUp()
            
            // then
            let updater = try #require(await systemModelRef.updater)
            await #expect(updater.isExist == true)
        }
        @Test func whenAlreadySetUp() async throws {
            // given
            await systemModelRef.setUp()
            
            let oldUpdater = try #require(await systemModelRef.updater)
            
            // when
            await systemModelRef.setUp()
            
            // then
            let newUpdater = try #require(await systemModelRef.updater)
            #expect(newUpdater == oldUpdater)
            
            let issue = try #require(await systemModelRef.issue as? KnownIssue)
            #expect(issue.reason == "alreadySetUp")
            
        }
    }

}
