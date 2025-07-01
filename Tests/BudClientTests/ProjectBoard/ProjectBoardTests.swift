//
//  ProjectBoardTests.swift
//  BudClient
//
//  Created by 김민우 on 6/26/25.
//
import Testing
import Tools
@testable import BudClient
@testable import BudServer


// MARK: Tests
@Suite("ProjectBoard", .timeLimit(.minutes(1)))
struct ProjectBoardTests {
    struct SetUpUpdater {
        let budClientRef: BudClient
        let projectBoardRef: ProjectBoard
        init() async {
            self.budClientRef = await BudClient()
            self.projectBoardRef = await getProjectBoard(budClientRef)
        }
        
        @Test func whenProjectBoardIsDeletedBeforeMutate() async throws {
            // given
            try await #require(projectBoardRef.id.isExist == true)
            
            // when
            await projectBoardRef.setUpUpdater {
                await projectBoardRef.delete()
            }
            
            // then
            try await #require(projectBoardRef.updater == nil)
            let debugIssue = try #require(await projectBoardRef.debugIssue)
            #expect(debugIssue.reason == "projectBoardIsDeleted")
        }
        
        @Test func createUpdater() async throws {
            // given
            try await #require(projectBoardRef.updater == nil)
            
            // when
            await projectBoardRef.setUpUpdater()
            
            // then
            let updater = try #require(await projectBoardRef.updater)
            await #expect(updater.isExist == true)
        }
        @Test func whenAlreadySetUp() async throws {
            // given
            try await #require(projectBoardRef.updater == nil)
    
            await projectBoardRef.setUpUpdater()
            
            let updater = try #require(await projectBoardRef.updater)
            
            // when
            await projectBoardRef.setUpUpdater()
            
            // then
            let newUpdater = try #require(await projectBoardRef.updater)
            #expect(newUpdater == updater)
        }
    }
    
    struct SubscribeProjectHub {
        let budClientRef: BudClient
        let projectBoardRef: ProjectBoard
        init() async {
            self.budClientRef = await BudClient()
            self.projectBoardRef = await getProjectBoardWithSetUp(budClientRef)
        }
        
        @Test func whenProjectBoardIsDeletedBeforeCapture() async throws {
            // given
            try await #require(projectBoardRef.id.isExist == true)
            
            // when
            await projectBoardRef.subscribeProjectHub(captureHook: {
                await projectBoardRef.delete()
            })

            // then
            let debugIssue = try #require(await projectBoardRef.debugIssue)
            #expect(debugIssue.reason == "projectBoardIsDeleted")
        }
        
        @Test func registerNotifierInProjectHub() async throws {
            // given
            let userId = projectBoardRef.userId
            let budServerLink = try #require(await budClientRef.budServerLink)
            let projectHubLink = budServerLink.getProjectHub()
            try await #require(projectHubLink.isNotifierExist(userId: userId) == false)
            
            // when
            await projectBoardRef.subscribeProjectHub()
            
            // then
            await #expect(projectHubLink.isNotifierExist(userId: userId) == true)
        }
    }
    
    struct UnsubscribeProjectHub {
        let budClientRef: BudClient
        let projectBoardRef: ProjectBoard
        init() async {
            self.budClientRef = await BudClient()
            self.projectBoardRef = await getProjectBoardWithSetUp(budClientRef)
        }
        
        @Test func whenProjectBoardIsDeletedBeforeCapture() async throws {
            // given
            try await #require(projectBoardRef.id.isExist == true)
            
            // when
            await projectBoardRef.unsubscribeProjectHub {
                await projectBoardRef.delete()
            }
            
            // then
            let debugIssue = try #require(await projectBoardRef.debugIssue)
            #expect(debugIssue.reason == "projectBoardIsDeleted")
        }
        
        @Test func unregisterNotifierInProjectHub() async throws {
            // given
            let userId = projectBoardRef.userId
            let budServerLink = try #require(await budClientRef.budServerLink)
            let projectHubLink = budServerLink.getProjectHub()
            
            await projectBoardRef.subscribeProjectHub()
            try await #require(projectHubLink.isNotifierExist(userId: userId) == true)
            
            // when
            await projectBoardRef.unsubscribeProjectHub()
            
            // then
            await #expect(projectHubLink.isNotifierExist(userId: userId) == false)
        }
    }
    
    struct CreateEmptyProject {
        let budClientRef: BudClient
        let projectBoardRef: ProjectBoard
        init() async {
            self.budClientRef = await BudClient()
            self.projectBoardRef = await getProjectBoardWithSetUp(budClientRef)
            
            await projectBoardRef.subscribeProjectHub()
        }
        
        @Test func createProjectSource() async throws {
            // given
            let budServerLink = try #require(await budClientRef.budServerLink)
            let projectHubLink = budServerLink.getProjectHub()
            
            let userId = try #require(await budClientRef.profileBoard?.ref?.userId)
            
            let oldProjects = await projectHubLink.getMyProjectSource(userId)
            #expect(oldProjects.isEmpty)
            
            // when
            await projectBoardRef.createProjectSource()
            
            // then
            let newProjects = await projectHubLink.getMyProjectSource(userId)
            #expect(newProjects.count == 1)
        }
        @Test func updateProjectsInProjectBoard() async throws {
            // given
            try await #require(projectBoardRef.projects.isEmpty)
            
            // when
            await confirmation(expectedCount: 1) { confirm in
                await withCheckedContinuation { continuation in
                    Task.detached {
                        await projectBoardRef.subscribeProjectHub {
                            confirm()
                            continuation.resume()
                        } removeCallback: {
                            
                        }
                        
                        await projectBoardRef.createProjectSource()
                    }
                }
            }
            
            // then
            await #expect(projectBoardRef.projects.count == 1)
            
            // when
            await confirmation(expectedCount: 1) { confirm in
                await withCheckedContinuation { continuation in
                    Task.detached {
                        await projectBoardRef.subscribeProjectHub {
                            confirm()
                            continuation.resume()
                        } removeCallback: {
                            
                        }
                        
                        await projectBoardRef.createProjectSource()
                    }
                }
            }
            
            
            // then
            await #expect(projectBoardRef.projects.count == 2)
        }
    }
}



// MARK: Helphers
private func getProjectBoard(_ budClientRef: BudClient) async -> ProjectBoard {
    await signIn(budClientRef)
    
    let projectBoard = await budClientRef.projectBoard!
    return await projectBoard.ref!
}
private func getProjectBoardWithSetUp(_ budClientRef: BudClient) async -> ProjectBoard {
    let projectBoardRef = await getProjectBoard(budClientRef)
    await projectBoardRef.setUpUpdater()
    
    try! await #require(projectBoardRef.updater?.isExist == true)
    return projectBoardRef
}
