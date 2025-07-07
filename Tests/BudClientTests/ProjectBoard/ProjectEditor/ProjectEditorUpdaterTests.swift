//
//  ProjectUpdaterTests.swift
//  BudClient
//
//  Created by 김민우 on 7/4/25.
//
import Foundation
import Testing
import Values
@testable import BudClient


// MARK: Tests
@Suite("ProjectUpdater")
struct ProjectUpdaterTests {
    struct Update {
        let budClientRef: BudClient
        let updaterRef: ProjectUpdater
        init() async {
            self.budClientRef = await BudClient()
            self.updaterRef = await getUpdater(budClientRef)
        }
        
        @Test func whenProjectUpdaterIsDeleted() async throws {
            // given
            try await #require(updaterRef.id.isExist == true)
            
            // when
            await updaterRef.update {
                await updaterRef.delete()
            }
            
            // then
            let issue = try #require(await updaterRef.issue as? KnownIssue)
            #expect(issue.reason == "projectUpdaterIsDeleted")
        }
        
        // modified
        @Test func dequeModifiedEvent() async throws {
            // given
            try await #require(updaterRef.queue.isEmpty == true)
            
            let event = ProjectSourceEvent.modified("TEST_NAME")
            
            // when
            await MainActor.run {
                updaterRef.queue.append(event)
            }
            await updaterRef.update()
            
            // then
            await #expect(updaterRef.queue.isEmpty == true)
        }
        @Test func updateNameInProject() async throws {
            // given
            let projectRef = try #require(await updaterRef.config.parent.ref)
            
            let testName = "TEST_NAME"
            let event = ProjectSourceEvent.modified("TEST_NAME")
            
            try await #require(projectRef.name != testName)
            
            // when
            await MainActor.run {
                updaterRef.queue.append(event)
            }
            await updaterRef.update()
            
            // then
            await #expect(projectRef.name == testName)
        }
        
        // added
        @Test func dequeAddedEvent() async throws { }
        @Test func createSystemModel() async throws { }
        
        // removed
        @Test func dequeRemovedEvent() async throws { }
        @Test func deleteSystemModel() async throws { }
    }
}


// MARK: Helphers
private func getUpdater(_ budClientRef: BudClient) async -> ProjectUpdater {
    let projectRef = await createAndGetProject(budClientRef)
    
    await projectRef.setUp()
    return try! #require(await projectRef.updater?.ref)
}
