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
@Suite("ProjectBoard", .timeLimit(.minutes(1)))
struct ProjectBoardTests {
    struct SetUp {
        let budClientRef: BudClient
        let projectBoardRef: ProjectBoard
        init() async {
            self.budClientRef = await BudClient()
            self.projectBoardRef = await getProjectBoard(budClientRef)
        }
        
        @Test func createUpdater() async throws {
            // given
            try await #require(projectBoardRef.updater == nil)
            
            // when
            await projectBoardRef.setUp()
            
            // then
            let updater = try #require(await projectBoardRef.updater)
            await #expect(updater.isExist == true)
        }
        @Test func whenAlreadySetUp() async throws {
            // given
            try await #require(projectBoardRef.updater == nil)
    
            await projectBoardRef.setUp()
            
            let updater = try #require(await projectBoardRef.updater)
            
            // when
            await projectBoardRef.setUp()
            
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
            self.projectBoardRef = await getProjectBoard(budClientRef)
            
            await projectBoardRef.setUp()
        }
        
        @Test func getEventOfProjectCreation() async throws {
            // given
            try await #require(projectBoardRef.projects.isEmpty)
            
            // when
            await confirmation(expectedCount: 1) { confirm in
                await withCheckedContinuation { continuation in
                    Task.detached {
                        await projectBoardRef.startObserving {
                            confirm()
                            continuation.resume()
                        }
                        
                        await projectBoardRef.createEmptyProject()
                    }
                }
            }
            
            
            // then
            await #expect(projectBoardRef.projects.count == 1)
        }
    }
    
    struct StopObserving {
        let budClientRef: BudClient
        let projectBoardRef: ProjectBoard
        init() async {
            self.budClientRef = await BudClient()
            self.projectBoardRef = await getProjectBoard(budClientRef)
        }
    }
    
    struct CreateEmptyProject {
        let budClientRef: BudClient
        let projectBoardRef: ProjectBoard
        init() async {
            self.budClientRef = await BudClient()
            self.projectBoardRef = await getProjectBoard(budClientRef)
            
            await projectBoardRef.startObserving()
        }

        // ProjectBoard.startObserving을 구현한 뒤에 테스트 작성
        @Test(.disabled()) func appendInProjectSourceMap() async throws {
            // given
            try await #require(projectBoardRef.projectSourceMap.isEmpty == true)
            
            // when
            await projectBoardRef.createEmptyProject()
            
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
            await projectBoardRef.createEmptyProject()
            
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
