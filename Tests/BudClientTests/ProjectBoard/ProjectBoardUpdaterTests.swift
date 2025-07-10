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
        
        @Test func whenEditorAlreadyAdded() async throws {
            // given
            await withCheckedContinuation { con in
                Task {
                    await projectBoardRef.setCallback {
                        con.resume()
                    }
                    
                    await projectBoardRef.subscribe()
                    await projectBoardRef.createNewProject()
                }
            }
            
            try await #require(projectBoardRef.editors.count == 1)
            
            let projectEditorRef = try #require(await projectBoardRef.editors.first?.ref)
            let projectSourceRef = try #require(await projectEditorRef.source.ref)
            
            // when
            let diff = ProjectSourceDiff(
                id: projectSourceRef.id,
                target: projectEditorRef.target,
                name: "DUPLICATE")
            
            await updaterRef.appendEvent(.added(diff))
            await updaterRef.update()
            
            // then
            await #expect(projectBoardRef.editors.count == 1)
            
            let issue = try #require(await updaterRef.issue as? KnownIssue)
            #expect(issue.reason == "alreadyAdded")
        }
        @Test func createProject() async throws {
            // given
            try await #require(projectBoardRef.editors.isEmpty == true)
            
            let newProjectSource = ProjectSourceMock.ID()
            let newProject = ProjectID()
            
            let diff = ProjectSourceDiff(id: newProjectSource,
                                         target: newProject,
                                         name: "")
            
            await updaterRef.appendEvent(.added(diff))
            
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
            let newProjectSource = ProjectSourceMock.ID()
            
            let diff = ProjectSourceDiff(id: newProjectSource,
                                         target: newProject,
                                         name: "")
            await updaterRef.appendEvent(.added(diff))
            
            // when
            await updaterRef.update()
            
            // then
            await #expect(updaterRef.queue.isEmpty)
        }
        
        @Test func whenEditorAlreadyRemoved() async throws {
            // given
            try await #require(projectBoardRef.editors.isEmpty == true)
            
            let newProject = ProjectID()
            let newProjectSource = ProjectSourceMock.ID()
            
            let diff = ProjectSourceDiff(id: newProjectSource,
                                         target: newProject,
                                         name: "")
            
            await updaterRef.appendEvent(.added(diff))
            await updaterRef.update()
            
            try await #require(updaterRef.issue == nil)
            try await #require(projectBoardRef.editors.count == 1)
            try await #require(updaterRef.queue.isEmpty == true)
            
            let projectEditor = try #require(await projectBoardRef.editors.first)
            let project = try #require(await projectEditor.ref?.target)
            
            // given
            let removedDiff = ProjectSourceDiff(id: newProjectSource,
                                                target: newProject,
                                                name: "")
            
            await updaterRef.appendEvent(.removed(removedDiff))
            
            await updaterRef.update()
            
            // when
            await updaterRef.appendEvent(.removed(removedDiff))
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
                    await projectBoardRef.createNewProject()
                }
            }
            
            await projectBoardRef.unsubscribe()
            try await #require(projectBoardRef.editors.count == 1)
            
            let projectEditor = try #require(await projectBoardRef.editors.first)
            let projectEditorRef = try #require(await projectEditor.ref)
            
            let diff = ProjectSourceDiff(id: projectEditorRef.source,
                                         target: projectEditorRef.target,
                                         name: "")
            
            // when
            await updaterRef.appendEvent(.removed(diff))
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
    
    return await projectBoardRef.updater
}

