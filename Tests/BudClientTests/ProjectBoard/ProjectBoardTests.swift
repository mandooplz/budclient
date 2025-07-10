//
//  ProjectBoardTests.swift
//  BudClient
//
//  Created by 김민우 on 6/26/25.
//
import Testing
import Values
@testable import BudClient
@testable import BudServer


// MARK: Tests
@Suite("ProjectBoard", .timeLimit(.minutes(1)))
struct ProjectBoardTests {
    struct Subscribe {
        let budClientRef: BudClient
        let projectBoardRef: ProjectBoard
        init() async {
            self.budClientRef = await BudClient()
            self.projectBoardRef = await getProjectBoard(budClientRef)
        }
        
        @Test func whenProjectBoardIsDeletedBeforeCapture() async throws {
            // given
            try await #require(projectBoardRef.id.isExist == true)
            
            // when
            await projectBoardRef.subscribe(captureHook: {
                await projectBoardRef.delete()
            })

            // then
            let issue = try #require(await projectBoardRef.issue as? KnownIssue)
            #expect(issue.reason == "projectBoardIsDeleted")
        }
        
        @Test func setHandlerInProjectHub() async throws {
            // given
            let config = projectBoardRef.config
            let projectHubLink = await config.budServerLink.getProjectHub()
            let me = await ObjectID(projectBoardRef.id.value)
            
            try await #require(projectHubLink.hasHandler(requester: me) == false)
            
            // when
            await projectBoardRef.subscribe()
            
            // then
            await #expect(projectHubLink.hasHandler(requester: me) == true)
        }
    }
    
    struct Unsubscribe {
        let budClientRef: BudClient
        let projectBoardRef: ProjectBoard
        init() async {
            self.budClientRef = await BudClient()
            self.projectBoardRef = await getProjectBoard(budClientRef)
        }
        
        @Test func removeHandlerInProjectHub() async throws {
            // given
            let config = projectBoardRef.config
            let projectHubLink = await config.budServerLink.getProjectHub()
            let me = await ObjectID(projectBoardRef.id.value)
            
            await projectBoardRef.subscribe()
            try await #require(projectHubLink.hasHandler(requester: me) == true)
            
            // when
            await projectBoardRef.unsubscribe()
            
            // then
            await #expect(projectHubLink.hasHandler(requester: me) == false)
        }
    }
    
    struct CreateProject {
        let budClientRef: BudClient
        let projectBoardRef: ProjectBoard
        init() async {
            self.budClientRef = await BudClient()
            self.projectBoardRef = await getProjectBoard(budClientRef)
        }
        
        @Test func whenProjectBoardIsDeletedBeforeCapture() async throws {
            // given
            try await #require(projectBoardRef.id.isExist == true)
            
            // when
            await projectBoardRef.createProject {
                await projectBoardRef.delete()
            }
            
            // then
            try await #require(projectBoardRef.id.isExist == false)
            
            let issue = try #require(await projectBoardRef.issue as? KnownIssue)
            #expect(issue.reason == "projectBoardIsDeleted")
        }
        
        @Test func appendProject() async throws {
            // given
            try await #require(projectBoardRef.editors.isEmpty)
            
            // when
            await withCheckedContinuation { con in
                Task {
                    await projectBoardRef.setCallback {
                        con.resume()
                    }
                    
                    await projectBoardRef.subscribe()
                    await projectBoardRef.createProject()
                }
            }

            
            // then
            await projectBoardRef.unsubscribe()
            await #expect(projectBoardRef.editors.count == 1)
            
            // when
            await withCheckedContinuation { con in
                Task.detached {
                    await projectBoardRef.setCallback {
                        con.resume()
                    }
                    
                    await projectBoardRef.subscribe()
                    await projectBoardRef.createProject()
                }
            }
            
            
            // then
            await #expect(projectBoardRef.editors.count == 2)
        }
    }
}



// MARK: Helphers
private func getProjectBoard(_ budClientRef: BudClient) async -> ProjectBoard {
    await signIn(budClientRef)
    
    let projectBoard = await budClientRef.projectBoard!
    return await projectBoard.ref!
}
