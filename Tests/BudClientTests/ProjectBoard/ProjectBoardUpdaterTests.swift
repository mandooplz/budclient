//
//  ProjectBoardUpdaterTests.swift
//  BudClient
//
//  Created by 김민우 on 7/1/25.
//
import Foundation
import Testing
import Values
@testable import BudClient
@testable import BudServer


// MARK: Tests
@Suite("ProjectBoardUpdater", .timeLimit(.minutes(1)))
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
        
        @Test func whenEditorAlreadyAdded() async throws {
            // given
            await withCheckedContinuation { con in
                Task {
                    await projectBoardRef.setCallback {
                        con.resume()
                    }
                    
                    await projectBoardRef.subscribe()
                    await projectBoardRef.createProject()
                }
            }
            
            try await #require(projectBoardRef.editors.count == 1)
            
            let projectEditorRef = try #require(await projectBoardRef.editors.first?.ref)
            let projectSource = projectEditorRef.sourceLink.object
            
            // when
            await MainActor.run {
                let event = ProjectHubEvent.added(projectSource, projectEditorRef.target)
                updaterRef.queue.append(event)
            }
            await updaterRef.update()
            
            // then
            await #expect(projectBoardRef.editors.count == 1)
            
            let issue = try #require(await updaterRef.issue as? KnownIssue)
            #expect(issue.reason == "alreadyAdded")
        }
        @Test func createProject() async throws {
            // given
            try await #require(projectBoardRef.editors.isEmpty == true)
            
            let newProject = ProjectID()
            let _ = await MainActor.run {
                let event = ProjectHubEvent.added(ProjectSourceID(), newProject)
                updaterRef.queue.append(event)
            }
            
            // when
            await updaterRef.update()
            
            // then
            try await #require(updaterRef.issue == nil)
            
            try await #require(projectBoardRef.editors.count == 1)
            let projectEditor = try #require(await projectBoardRef.editors.first)
            let projectEditorRef = try #require(await projectEditor.ref)
            
            #expect(projectEditorRef.target == newProject)
        }
        @Test func removeEventWhenAdded() async throws {
            // given
            let newProject = ProjectID()
            let newProjectSource = ProjectSourceID()
            
            await MainActor.run {
                let event = ProjectHubEvent.added(newProjectSource, newProject)
                updaterRef.queue.append(event)
            }
            
            // when
            await updaterRef.update()
            
            // then
            await #expect(updaterRef.queue.isEmpty)
        }
        
        @Test func whenEditorAlreadyRemoved() async throws {
            // given
            try await #require(projectBoardRef.editors.isEmpty == true)
            
            let newProject = ProjectID()
            let newProjectSource = ProjectSourceID()
            await MainActor.run {
                let event = ProjectHubEvent.added(newProjectSource, newProject)
                updaterRef.queue.append(event)
            }
            await updaterRef.update()
            
            try await #require(updaterRef.issue == nil)
            try await #require(projectBoardRef.editors.count == 1)
            try await #require(updaterRef.queue.isEmpty == true)
            
            let projectEditor = try #require(await projectBoardRef.editors.first)
            let project = try #require(await projectEditor.ref?.target)
            
            // given
            await MainActor.run {
                let event = ProjectHubEvent.removed(project)
                updaterRef.queue.append(event)
                
            }
            
            await updaterRef.update()
            
            // when
            await MainActor.run {
                let event = ProjectHubEvent.removed(project)
                updaterRef.queue.append(event)
                
            }
            await updaterRef.update()
            
            // then
            await #expect(projectBoardRef.editors.isEmpty == true)
            await #expect(projectEditor.isExist == false)
            
            let issue = try #require(await updaterRef.issue as? KnownIssue)
            #expect(issue.reason == "alreadyRemoved")
        }
        @Test func removeProjectEditor() async throws {
            // given
            try await #require(projectBoardRef.editors.isEmpty == true)
            await withCheckedContinuation { con in
                Task {
                    await projectBoardRef.setCallback {
                        con.resume()
                    }
                    
                    await projectBoardRef.subscribe()
                    await projectBoardRef.createProject()
                }
            }
            
            try await #require(projectBoardRef.editors.count == 1)
            
            let projectEditor = try #require(await projectBoardRef.editors.first)
            let project = try #require(await projectEditor.ref?.target)
            
            // when
            await MainActor.run {
                let event = ProjectHubEvent.removed(project)
                updaterRef.queue.append(event)
            }
            await updaterRef.update()
            
            // then
            try await #require(projectBoardRef.issue == nil)
            
            await #expect(projectBoardRef.editors.isEmpty == true)
            await #expect(projectEditor.isExist == false)
        }
    }
}


// MARK: Helpher
private func getUpdater(_ budClientRef: BudClient) async -> ProjectBoardUpdater {
    await signIn(budClientRef)
    
    let projectBoard = await budClientRef.projectBoard!
    let projectBoardRef = await projectBoard.ref!
    
    await projectBoardRef.setUp()
    return await projectBoardRef.updater!.ref!
}

