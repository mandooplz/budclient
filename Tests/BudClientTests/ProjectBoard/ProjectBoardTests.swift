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
    }
}



// MARK: Helphers
private func getProjectBoard(_ budClientRef: BudClient) async -> ProjectBoard {
    await signIn(budClientRef)
    
    let projectBoard = await budClientRef.projectBoard!
    return await projectBoard.ref!
}
