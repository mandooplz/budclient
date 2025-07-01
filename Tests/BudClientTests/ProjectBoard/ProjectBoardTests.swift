//
//  ProjectBoardTests.swift
//  BudClient
//
//  Created by 김민우 on 6/26/25.
//
import Testing
import Tools
@testable import BudClient


// MARK: Tests
// 여기에 더 추가할 테스트는 없는가.
@Suite("ProjectBoard", .timeLimit(.minutes(1)))
struct ProjectBoardTests {
    struct SetUp {
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
    
    struct StartObserving {
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
            await projectBoardRef.startObserving(captureHook: {
                await projectBoardRef.delete()
            })

            // then
            let debugIssue = try #require(await projectBoardRef.debugIssue)
            #expect(debugIssue.reason == "projectBoardIsDeleted")
        }
        
        @Test func whenNewProjectSourceIsAdded() async throws {
            // given
            try await #require(projectBoardRef.projects.isEmpty)
            
            // when
            await confirmation(expectedCount: 1) { confirm in
                await withCheckedContinuation { continuation in
                    Task.detached {
                        await projectBoardRef.startObserving {
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
        }
        @Test func whenTwoProjectSourceIsAdded() async throws {
            // given
            try await #require(projectBoardRef.projects.isEmpty)
            
            // when
            await confirmation(expectedCount: 1) { confirm in
                await withCheckedContinuation { continuation in
                    Task.detached {
                        await projectBoardRef.startObserving {
                            confirm()
                            continuation.resume()
                        } removeCallback: {
                            
                        }
                        
                        await projectBoardRef.createProjectSource()
                    }
                }
            }
            
            await confirmation(expectedCount: 1) { confirm in
                await withCheckedContinuation { continuation in
                    Task.detached {
                        await projectBoardRef.startObserving {
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
    
    struct StopObserving {
        let budClientRef: BudClient
        let projectBoardRef: ProjectBoard
        init() async {
            self.budClientRef = await BudClient()
            self.projectBoardRef = await getProjectBoardWithSetUp(budClientRef)
        }
        
        @Test func whenNewProjectSourceIsAdded() async throws {
            // given
            try await #require(projectBoardRef.projects.isEmpty)
            
            await withCheckedContinuation { continuation in
                Task {
                    await projectBoardRef.startObserving {
                        continuation.resume()
                    } 
                    
                    await projectBoardRef.createProjectSource()
                }
            }
            
            await #expect(projectBoardRef.projects.count == 1)
            
            // when
            await projectBoardRef.stopObserving()
            
            // then
            await projectBoardRef.createProjectSource()
            
            await #expect(projectBoardRef.projects.count == 1)
        }
    }
    
    struct CreateEmptyProject {
        let budClientRef: BudClient
        let projectBoardRef: ProjectBoard
        init() async {
            self.budClientRef = await BudClient()
            self.projectBoardRef = await getProjectBoardWithSetUp(budClientRef)
            
            await projectBoardRef.startObserving()
        }

        // ProjectBoard.startObserving을 구현한 뒤에 테스트 작성
        @Test(.disabled()) func appendInProjectSourceMap() async throws {
            // given
            try await #require(projectBoardRef.projectSourceMap.isEmpty == true)
            
            // when
            await projectBoardRef.createProjectSource()
            
            // then
            let project = try #require(await projectBoardRef.projects.first)
            let mapValues = await projectBoardRef.projectSourceMap.values
            #expect(mapValues.contains(project) == true)
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
