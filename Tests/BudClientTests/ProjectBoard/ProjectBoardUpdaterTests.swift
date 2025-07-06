//
//  ProjectBoardUpdaterTests.swift
//  BudClient
//
//  Created by 김민우 on 7/1/25.
//
import Foundation
import Testing
import Tools
@testable import BudClient
import BudServer


// MARK: Tests
@Suite("ProjectBoardUpdater")
struct ProjectBoardUpdaterTests {
    struct Update {
        let budClientRef: BudClient
        let projectBoardRef: ProjectBoard
        let updaterRef: ProjectBoardUpdater
        init() async {
            self.budClientRef = await BudClient()
            self.updaterRef = await getUpdater(budClientRef)
            self.projectBoardRef = await updaterRef.config.parent.ref!
        }
        
        @Test func whenUpdaterIsDeletedBeforeMutate() async throws {
            // given
            try await #require(updaterRef.id.isExist == true)
            
            // when
            await updaterRef.update {
                await updaterRef.delete()
            }
            
            // then
            let issue = try #require(await updaterRef.issue as? KnownIssue)
            #expect(issue.reason == "updaterIsDeleted")
        }
        
        @Test func whenAlreadyAdded() async throws {
            // given
            await withCheckedContinuation { con in
                Task {
                    await projectBoardRef.setCallback {
                        con.resume()
                    }
                    
                    await projectBoardRef.subscribeProjectHub()
                    await projectBoardRef.createProjectSource()
                }
            }
            
            try await #require(projectBoardRef.projects.count == 1)
            
            let project = try #require(await projectBoardRef.projects.first)
            let projectSource = try #require(await projectBoardRef
                .projectSourceMap
                .first { $0.value == project }?
                .key)
            
            // when
            await MainActor.run {
                let event = ProjectHubEvent.added(projectSource)
                updaterRef.queue.append(event)
            }
            await updaterRef.update()
            
            // then
            await #expect(projectBoardRef.projects.count == 1)
            await #expect(projectBoardRef.projectSourceMap.count == 1)
        }
        @Test func createProject() async throws {
            // given
            try await #require(projectBoardRef.projects.isEmpty == true)
            
            let target = ProjectID()
            
            let _ = await MainActor.run {
                let event = ProjectHubEvent.added(target)
                updaterRef.queue.append(event)
            }
            
            // when
            await updaterRef.update()
            
            // then
            try await #require(projectBoardRef.projects.count == 1)
            let project = try #require(await projectBoardRef.projects.first)
            let projectRef = try #require(await project.ref)
            
            #expect(projectRef.target == target)
        }
        @Test func insertProjectSource() async throws {
            // given
            try await #require(projectBoardRef.projectSourceMap.isEmpty == true)
            
            let target = ProjectID()
            
            let _ = await MainActor.run {
                let event = ProjectHubEvent.added(target)
                updaterRef.queue.append(event)
            }
            
            // when
            await updaterRef.update()
            
            // then
            await #expect(projectBoardRef.projectSourceMap[target] != nil)
        }
        @Test func removeEventWhenAdded() async throws {
            // given
            let target = ProjectID()
            
            await MainActor.run {
                let event = ProjectHubEvent.added(target)
                updaterRef.queue.append(event)
            }
            
            // when
            await updaterRef.update()
            
            // then
            await #expect(updaterRef.queue.isEmpty)
        }
        
        @Test func whenAlreadyRemoved() async throws {
            // given
            try await #require(projectBoardRef.projects.isEmpty == true)
            
            let target = ProjectID()
            
            // when
            await MainActor.run {
                let event = ProjectHubEvent.removed(target)
                updaterRef.queue.append(event)
            }
            await updaterRef.update()
            
            
            // then
            let issue = try #require(await updaterRef.issue  as? KnownIssue)
            #expect(issue.reason == "alreadyRemoved")
        }
        @Test func deleteProjectWhenSourceRemoved() async throws {
            // given
            try await #require(projectBoardRef.projects.isEmpty == true)
            
            let target = ProjectID()
            
            await MainActor.run {
                let event = ProjectHubEvent.added(target)
                
                updaterRef.queue.append(event)
            }
            await updaterRef.update()
            
            try await #require(projectBoardRef.projects.count == 1)
            try await #require(updaterRef.queue.isEmpty == true)
            
            let project = try #require(await projectBoardRef.projects.first)
            
            
            // given
            await MainActor.run {
                let event = ProjectHubEvent.removed(target)
                
                updaterRef.queue.append(event)
            }
            
            // when
            await updaterRef.update()
            
            // then
            await #expect(projectBoardRef.projects.isEmpty == true)
            await #expect(project.isExist == false)
        }
        @Test func removeProjectSource() async throws {
            // given
            try await #require(projectBoardRef.projects.isEmpty == true)
            await withCheckedContinuation { con in
                Task {
                    await projectBoardRef.setCallback {
                        con.resume()
                    }
                    
                    await projectBoardRef.subscribeProjectHub()
                    await projectBoardRef.createProjectSource()
                }
            }
            
            try await #require(projectBoardRef.projects.count == 1)
            
            let project = try #require(await projectBoardRef.projects.first)
            let projectSource = try #require(await projectBoardRef.getProjectSource(project))
            
            // when
            await MainActor.run {
                let event = ProjectHubEvent.removed(projectSource)
                updaterRef.queue.append(event)
            }
            await updaterRef.update()
            
            // then
            await #expect(projectBoardRef.projects.isEmpty == true)
        }
        @Test func removeValueInProjectSourceMap() async throws {
            // given
            let budClientRef = await BudClient()
            let _ = await createAndGetProject(budClientRef)
            let projectBoardRef = await budClientRef.projectBoard!.ref!
            let updaterRef = await projectBoardRef.updater!.ref!
            
            try await #require(projectBoardRef.projects.count == 1)
            try await #require(projectBoardRef.projectSourceMap.count == 1)
            
            let project = try #require(await projectBoardRef.projects.first)
            let projectSource = try #require(await projectBoardRef.getProjectSource(project))
            
            // when
            await MainActor.run {
                let event = ProjectHubEvent.removed(projectSource)
                updaterRef.queue.append(event)
            }
            await updaterRef.update()
            
            // then
            try await #require(projectBoardRef.projects.count == 0)
            await #expect(projectBoardRef.projectSourceMap.count == 0)
        }
    }
}


// MARK: Helpher
private func getUpdater(_ budClientRef: BudClient) async -> ProjectBoardUpdater {
    await signIn(budClientRef)
    
    let projectBoard = await budClientRef.projectBoard!
    let projectBoardRef = await projectBoard.ref!
    
    await projectBoardRef.setUpUpdater()
    return await projectBoardRef.updater!.ref!
}
