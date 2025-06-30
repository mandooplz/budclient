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
@Suite("ProjectBoard")
struct ProjectBoardTests {
    struct CreateEmptyProject {
        let budClientRef: BudClient
        let projectBoardRef: ProjectBoard
        init() async {
            self.budClientRef = await BudClient()
            self.projectBoardRef = await getProjectBoard(budClientRef)
        }
        
        @Test func appendProject() async throws {
            // given
            try await #require(projectBoardRef.projects.isEmpty == true)
            
            // when
            await projectBoardRef.createEmptyProject()
            
            // then
            await #expect(projectBoardRef.projects.count == 1)
        }
        @Test func createProject() async throws {
            // given
            try await #require(projectBoardRef.projects.isEmpty == true)
            
            // when
            await projectBoardRef.createEmptyProject()
            
            // then
            let project = try #require(await projectBoardRef.projects.first)
            await #expect(project.isExist == true)
        }
        
        @Test func createProjectSourceInBudServe() async throws {
            
        }
    }
    
    struct StartObserving {
        let budClientRef: BudClient
        let projectBoardRef: ProjectBoard
        init() async {
            self.budClientRef = await BudClient()
            self.projectBoardRef = await getProjectBoard(budClientRef)
        }
        
        @Test func getEventOfProjectCreation() async throws { }
    }
    
    struct StopObserving {
        let budClientRef: BudClient
        let projectBoardRef: ProjectBoard
        init() async {
            self.budClientRef = await BudClient()
            self.projectBoardRef = await getProjectBoard(budClientRef)
        }
    }
}



// MARK: Helphers
private func getProjectBoard(_ budClientRef: BudClient) async -> ProjectBoard {
    await signIn(budClientRef)
    
    let projectBoard = await budClientRef.projectBoard!
    return await projectBoard.ref!
}
