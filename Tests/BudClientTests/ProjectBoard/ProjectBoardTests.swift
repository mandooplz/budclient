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
            let issue = try #require(await projectBoardRef.issue as? KnownIssue)
            #expect(issue.reason == "projectBoardIsDeleted")
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
        @Test func whenUpdaterAlreadySetUp() async throws {
            // given
            try await #require(projectBoardRef.updater == nil)
    
            await projectBoardRef.setUpUpdater()
            
            let updater = try #require(await projectBoardRef.updater)
            
            // when
            await projectBoardRef.setUpUpdater()
            
            // then
            let issue = try #require(await projectBoardRef.issue as? KnownIssue)
            try #require(issue.reason == "alreadySetUp")
            
            
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
            let issue = try #require(await projectBoardRef.issue as? KnownIssue)
            #expect(issue.reason == "projectBoardIsDeleted")
        }
        @Test func whenUpdaterIsNil() async throws {
            // given
            await MainActor.run {
                projectBoardRef.updater = nil
            }
            
            // when
            await projectBoardRef.subscribeProjectHub()
            
            // then
            let issue = try #require(await projectBoardRef.issue as? KnownIssue)
            #expect(issue.reason == "updaterIsNotSet")
        }
        
        @Test func registerNotifierInProjectHub() async throws {
            // given
            let config = projectBoardRef.config
            let projectHubLink = await config.budServerLink.getProjectHub()
            let object = await ObjectID(projectBoardRef.id.value)
            
            try await #require(projectHubLink.hasHandler(object: object) == false)
            
            // when
            await projectBoardRef.subscribeProjectHub()
            
            // then
            await #expect(projectHubLink.hasHandler(object: object) == true)
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
            let issue = try #require(await projectBoardRef.issue as? KnownIssue)
            #expect(issue.reason == "projectBoardIsDeleted")
        }
        
        @Test func unregisterNotifierInProjectHub() async throws {
            // given
            let config = projectBoardRef.config
            let projectHubLink = await config.budServerLink.getProjectHub()
            let object = await ObjectID(projectBoardRef.id.value)
            
            await projectBoardRef.subscribeProjectHub()
            try await #require(projectHubLink.hasHandler(object: object) == true)
            
            // when
            await projectBoardRef.unsubscribeProjectHub()
            
            // then
            await #expect(projectHubLink.hasHandler(object: object) == false)
        }
    }
    
    struct CreateProjectSource {
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
            await projectBoardRef.createProjectSource {
                await projectBoardRef.delete()
            }
            
            // then
            try await #require(projectBoardRef.id.isExist == false)
            
            let issue = try #require(await projectBoardRef.issue as? KnownIssue)
            #expect(issue.reason == "projectBoardIsDeleted")
        }
        @Test func whenUpdaterIsNil() async throws {
            // given
            await MainActor.run {
                projectBoardRef.updater = nil
            }
            
            // when
            await projectBoardRef.createProjectSource()
            
            // then
            let issue = try #require(await projectBoardRef.issue as? KnownIssue)
            #expect(issue.reason == "updaterIsNotSet")
        }
        
        @Test func appendProject() async throws {
            // given
            try await #require(projectBoardRef.projects.isEmpty)
            
            // when
            await withCheckedContinuation { con in
                Task {
                    await projectBoardRef.setCallback {
                        con.resume()
                    }
                    
                    await projectBoardRef.subscribeProjectHub()
                    await projectBoardRef.createProjectSource()
                }
            }

            
            // then
            await projectBoardRef.unsubscribeProjectHub()
            await #expect(projectBoardRef.projects.count == 1)
            
            // when
            await withCheckedContinuation { con in
                Task.detached {
                    await projectBoardRef.setCallback {
                        con.resume()
                    }
                    
                    await projectBoardRef.subscribeProjectHub()
                    await projectBoardRef.createProjectSource()
                }
            }
            
            
            // then
            await #expect(projectBoardRef.projects.count == 2)
        }
        @Test func updateSourceMap() async throws {
            // given
            try await #require(projectBoardRef.projectSourceMap.isEmpty)
            
            // when
            await withCheckedContinuation { con in
                Task {
                    await projectBoardRef.setCallback {
                        con.resume()
                    }
                    
                    await projectBoardRef.subscribeProjectHub()
                    await projectBoardRef.createProjectSource()
                }
            }
            
            // then
            await #expect(projectBoardRef.projectSourceMap.count == 1)
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
