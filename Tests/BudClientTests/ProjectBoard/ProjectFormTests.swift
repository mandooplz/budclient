//
//  ProjectFormTests.swift
//  BudClient
//
//  Created by 김민우 on 7/1/25.
//
import Testing
import Tools
@testable import BudClient
@testable import BudServer


// MARK: Tests
@Suite("ProjectForm")
struct ProjectFormTests {
    struct Submit {
        let budClientRef: BudClient
        let projectFormRef: ProjectForm
        init() async {
            self.budClientRef = await BudClient()
            self.projectFormRef = await getProjectForm(budClientRef)
        }
        
        @Test func whenProjetFormIsDeleteBeforeCompute() async throws {
            // given
            try await #require(projectFormRef.id.isExist == true)
            
            // when
            await projectFormRef.submit {
                await projectFormRef.delete()
            }
            
            // then
            try await #require(projectFormRef.id.isExist == false)
            
            let issue = try #require(await projectFormRef.issue)
            #expect(issue.reason == "projectFormIsDeleted")
        }
        @Test func updateProjectsInProjectBoard() async throws {
            // given
            let projectBoard = projectFormRef.config.parent
            let projectBoardRef = await projectBoard.ref!
            
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
                        
                        await projectFormRef.submit()
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
                        
                        await projectFormRef.submit()
                    }
                }
            }
            
            
            // then
            await #expect(projectBoardRef.projects.count == 2)
        }
    }
}


// MARK: Helphers
private func getProjectForm(_ budClientRef: BudClient) async -> ProjectForm {
    await signIn(budClientRef)
    
    let projectBoard = await budClientRef.projectBoard!
    let projectBoardRef = await projectBoard.ref!
    
    await projectBoardRef.setUpUpdater()
    try! await #require(projectBoardRef.updater != nil)
    
    await projectBoardRef.createProjectForm()
    let projectForm = try! #require(await projectBoardRef.projectForm)
    return await projectForm.ref!
}
