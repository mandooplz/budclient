//
//  ProjectUpdaterTests.swift
//  BudClient
//
//  Created by 김민우 on 7/4/25.
//
import Foundation
import Testing
import Tools
@testable import BudClient


// MARK: Tests
@Suite("ProjectUpdater")
struct ProjectUpdaterTests {
    struct Update {
        let budClientRef: BudClient
        let projectUpdaterRef: ProjectUpdater
        init() async {
            self.budClientRef = await BudClient()
            self.projectUpdaterRef = await getProjectUpdater(budClientRef)
        }
        
        @Test func whenProjectUpdaterIsDeleted() async throws {
            // given
            try await #require(projectUpdaterRef.id.isExist == true)
            
            // when
            await projectUpdaterRef.update {
                await projectUpdaterRef.delete()
            }
            
            // then
            let issue = try #require(await projectUpdaterRef.issue as? KnownIssue)
            #expect(issue.reason == "projectUpdaterIsDeleted")
        }
        
        @Test func removeEvent() async throws {
            // given
            try await #require(projectUpdaterRef.queue.isEmpty == true)
            
            let event = ProjectSourceEvent.modified("TEST_NAME")
            
            // when
            await MainActor.run {
                projectUpdaterRef.queue.append(event)
            }
            await projectUpdaterRef.update()
            
            // then
            await #expect(projectUpdaterRef.queue.isEmpty == true)
        }
        @Test func updateNameInProject() async throws {
            // given
            let projectRef = try #require(await projectUpdaterRef.config.parent.ref)
            
            let testName = "TEST_NAME"
            let event = ProjectSourceEvent.modified("TEST_NAME")
            
            try await #require(projectRef.name != testName)
            
            // when
            await MainActor.run {
                projectUpdaterRef.queue.append(event)
            }
            await projectUpdaterRef.update()
            
            // then
            await #expect(projectRef.name == testName)
        }
    }
}


// MARK: Helphers
private func getProjectUpdater(_ budClientRef: BudClient) async -> ProjectUpdater {
    let projectRef = await createAndGetProject(budClientRef)
    
    await projectRef.setUp()
    return try! #require(await projectRef.updater?.ref)
}
