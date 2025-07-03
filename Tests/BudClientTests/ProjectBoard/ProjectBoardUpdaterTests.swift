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
        
        @Test(.disabled()) func whenAlreadyAdded() async throws {
            // given
            
        }
        @Test func createProject() async throws {
            // given
            try await #require(projectBoardRef.projects.isEmpty == true)
            
            let projectSource = UUID().uuidString
            
            let _ = await MainActor.run {
                let event = ProjectHubEvent.added(projectSource)
                updaterRef.eventQueue.append(event)
            }
            
            // when
            await updaterRef.update()
            
            // then
            try await #require(projectBoardRef.projects.count == 1)
            let project = try #require(await projectBoardRef.projects.first)
            let projectRef = try #require(await project.ref)
            
            let link = ProjectSourceLink(mode: .test, id: projectSource)
            #expect(projectRef.sourceLink == link)
        }
        @Test func insertProjectSource() async throws {
            // given
            try await #require(projectBoardRef.sourceMap.isEmpty == true)
            
            let projectSource = UUID().uuidString
            
            let _ = await MainActor.run {
                let event = ProjectHubEvent.added(projectSource)
                updaterRef.eventQueue.append(event)
            }
            
            // when
            await updaterRef.update()
            
            // then
            await #expect(projectBoardRef.sourceMap[projectSource] != nil)
        }
        
        @Test(.disabled()) func whenAlreadyRemoved() async throws {
            
        }
        @Test func deleteProjectWhenSourceRemoved() async throws {
            // given
            try await #require(projectBoardRef.projects.isEmpty == true)
            
            let randomProjectSource = UUID().uuidString
            
            await MainActor.run {
                let event = ProjectHubEvent.added(randomProjectSource)
                
                updaterRef.eventQueue.append(event)
                updaterRef.update()
            }
            
            try await #require(projectBoardRef.projects.count == 1)
            try await #require(updaterRef.eventQueue.isEmpty == true)
            
            let project = try #require(await projectBoardRef.projects.first)
            
            
            // given
            await MainActor.run {
                let event = ProjectHubEvent.removed(randomProjectSource)
                
                updaterRef.eventQueue.append(event)
            }
            
            // when
            await updaterRef.update()
            
            // then
            await #expect(projectBoardRef.projects.isEmpty == true)
            await #expect(project.isExist == false)
        }
        @Test(.disabled()) func removeProjectSource() async throws {
            // given
            
            
            // when
            
            // then
            
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
