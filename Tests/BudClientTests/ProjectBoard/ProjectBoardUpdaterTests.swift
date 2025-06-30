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
            self.projectBoardRef = await updaterRef.projectBoard.ref!
        }
        
        @Test func createProjectWhenSourceAdded() async throws {
            // given
            try await #require(projectBoardRef.projects.isEmpty == true)
            
            let randomProjectSource = UUID().uuidString
            
            let _ = await MainActor.run {
                updaterRef.diffs.insert(.added(projectSource: randomProjectSource))
            }
            
            // when
            await updaterRef.update()
            
            // then
            try await #require(projectBoardRef.projects.count == 1)
            let project = try #require(await projectBoardRef.projects.first)
            let projectRef = try #require(await project.ref)
            
            #expect(projectRef.source == randomProjectSource)
        }
        @Test func deleteProjectWhenSourceRemoved() async throws {
            // given
            try await #require(projectBoardRef.projects.isEmpty == true)
            
            let randomProjectSource = UUID().uuidString
            
            let _ = await MainActor.run {
                updaterRef.diffs.insert(.added(projectSource: randomProjectSource))
            }
            
            await updaterRef.update()
            try await #require(projectBoardRef.projects.count == 1)
            
            // when
        }
        @Test func handleAddedAndRemoved() async throws {
            
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
