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
        
        @Test func whenAlreadyAdded() async throws {
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
            
            let projectRef = try #require(await projectBoardRef.editors.first?.ref)
            let projectSource = projectRef.sourceLink.object
            
            // when
            await MainActor.run {
                let event = ProjectHubEvent.added(projectSource, projectRef.target)
                updaterRef.queue.append(event)
            }
            await updaterRef.update()
            
            // then
            await #expect(projectBoardRef.editors.count == 1)
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
            let project = try #require(await projectBoardRef.editors.first)
            let projectRef = try #require(await project.ref)
            
            #expect(projectRef.target == newProject)
        }
        @Test func removeEventWhenAdded() async throws {
            // given
            let target = ProjectID()
            let projectSource = ProjectSourceID()
            
            await MainActor.run {
                let event = ProjectHubEvent.added(projectSource, target)
                updaterRef.queue.append(event)
            }
            
            // when
            await updaterRef.update()
            
            // then
            await #expect(updaterRef.queue.isEmpty)
        }
        
        @Test func deleteProjectWhenSourceRemoved() async throws {
            // given
            try await #require(projectBoardRef.editors.isEmpty == true)
            
            let newProjectSource = ProjectSourceID()
            let newProject = ProjectID()
            await MainActor.run {
                let event = ProjectHubEvent.added(newProjectSource, newProject)
                updaterRef.queue.append(event)
            }
            await updaterRef.update()
            
            try await #require(updaterRef.issue == nil)
            try await #require(projectBoardRef.editors.count == 1)
            try await #require(updaterRef.queue.isEmpty == true)
            
            let project = try #require(await projectBoardRef.editors.first)
            let target = try #require(await project.ref?.target)
            
            // given
            await MainActor.run {
                let event = ProjectHubEvent.removed(target)
                updaterRef.queue.append(event)
            }
            
            // when
            await updaterRef.update()
            
            // then
            await #expect(projectBoardRef.editors.isEmpty == true)
            await #expect(project.isExist == false)
        }
        @Test func removeProjectSource() async throws {
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
            
            let project = try #require(await projectBoardRef.editors.first)
            let target = try #require(await project.ref?.target)
            
            // when
            await MainActor.run {
                let event = ProjectHubEvent.removed(target)
                updaterRef.queue.append(event)
            }
            await updaterRef.update()
            
            // then
            await #expect(projectBoardRef.editors.isEmpty == true)
        }
        @Test func removeValueInProjectSourceMap() async throws {
            // given
            let budClientRef = await BudClient()
            let _ = await createAndGetProject(budClientRef)
            let projectBoardRef = await budClientRef.projectBoard!.ref!
            let updaterRef = await projectBoardRef.updater!.ref!
            
            try await #require(projectBoardRef.editors.count == 1)
            
            let project = try #require(await projectBoardRef.editors.first)
            let target = try #require(await project.ref?.target)
            
            // when
            await MainActor.run {
                let event = ProjectHubEvent.removed(target)
                updaterRef.queue.append(event)
            }
            await updaterRef.update()
            
            // then
            try await #require(projectBoardRef.editors.count == 0)
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

private func getProject(_ budClientRef: BudClient) async -> ProjectID {
    let budServerLink = await budClientRef.budServerLink!
    let projectHubLink = await budServerLink.getProjectHub()
    
    // create new Project
    let newProject = ProjectID()
    let ticket = CreateProjectSource(creator: .init(),
                                     target: newProject,
                                     name: "")
    
    await projectHubLink.insertTicket(ticket)
    try! await projectHubLink.createProjectSource()
    
    return newProject
}

