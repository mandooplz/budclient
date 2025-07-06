//
//  ProjectTests.swift
//  BudClient
//
//  Created by 김민우 on 7/1/25.
//
import Foundation
import Testing
import Tools
@testable import BudClient
@testable import BudServer


// MARK: Tests
@Suite("Project", .timeLimit(.minutes(1)))
struct ProjectTests {
    struct SetUp {
        let budClientRef: BudClient
        let projectRef: Project
        init() async {
            self.budClientRef = await BudClient()
            self.projectRef = await createAndGetProject(budClientRef)
        }
        
        @Test func wnenAlreadtSetUp() async throws {
            // given
            await projectRef.setUp()
            let updater = try #require(await projectRef.updater)
            let systemBoard = try #require(await projectRef.systemBoard)
            let flowBoard = try #require(await projectRef.flowBoard)
            
            // when
            await projectRef.setUp()
            
            // then
            let issue = try #require(await projectRef.issue as? KnownIssue)
            #expect(issue.reason == "alreadySetUp")
            
            let newUpdater = try #require(await projectRef.updater)
            #expect(newUpdater == updater)
            
            let newSystemBoard = try #require(await projectRef.systemBoard)
            #expect(newSystemBoard == systemBoard)
            
            let newFlowBoard = try #require(await projectRef.flowBoard)
            #expect(newFlowBoard == flowBoard)
        }
        @Test func whenProjectIsDeletedBeforeMutate() async throws {
            // given
            try await #require(projectRef.id.isExist == true)
            
            // when
            await projectRef.setUp {
                await projectRef.delete()
            }
            
            // then
            let issue = try #require(await projectRef.issue as? KnownIssue)
            #expect(issue.reason == "projectIsDeleted")
        }
        
        @Test func createProjectUpdater() async throws {
            // given
            try await #require(projectRef.updater == nil)
            
            // when
            await projectRef.setUp()
            
            // then
            let updater = try #require(await projectRef.updater)
            await #expect(updater.isExist == true)
        }
        @Test func createSystemBoard() async throws {
            // given
            try await #require(projectRef.systemBoard == nil)
            
            // when
            await projectRef.setUp()
            
            // then
            let systemBoard = try #require(await projectRef.systemBoard)
            await #expect(systemBoard.isExist == true)
        }
        @Test func createFlowBoard() async throws {
            // given
            try await #require(projectRef.flowBoard == nil)
            
            // when
            await projectRef.setUp()
            
            // then
            let flowBoard = try #require(await projectRef.flowBoard)
            await #expect(flowBoard.isExist == true)
        }
    }
    
    struct SubscribeSource {
        let budClientRef: BudClient
        let projectRef: Project
        init() async {
            self.budClientRef = await BudClient()
            self.projectRef = await createAndGetProject(budClientRef)
        }
        
        @Test func whenProjectIsDeletedBeforeCapture() async throws {
            // given
            try await #require(projectRef.id.isExist == true)
            
            // when
            await projectRef.subscribeSource {
                await projectRef.delete()
            }
            
            // then
            let issue = try #require(await projectRef.issue as? KnownIssue)
            #expect(issue.reason == "projectIsDeleted")
        }
        @Test func whenUpdaterIsNil() async throws {
            // given
            try await #require(projectRef.updater == nil)
            
            // when
            await projectRef.subscribeSource()
            
            // then
            let issue = try #require(await projectRef.issue as? KnownIssue)
            #expect(issue.reason == "updaterIsNil")
        }
        
        @Test func setHandlerInProjectSource() async throws {
            // given
            let sourceLink = projectRef.sourceLink
            let system = budClientRef.system
            try await #require(sourceLink.hasHandler(system: system) == false)
            
            await projectRef.setUp()
            
            // when
            await projectRef.subscribeSource()
            
            // then
            try await #expect(sourceLink.hasHandler(system: system) == true)
        }
        @Test func getUpdateFromProjectSource() async throws {
            // given
            let sourceLink = projectRef.sourceLink
            let testName = "JUST_TEST_NAME"
            
            try await #require(projectRef.name != testName)
            await projectRef.setUp()
            
            // when
            await withCheckedContinuation { con in
                Task {
                    await projectRef.setCallback {
                        con.resume()
                    }
                    
                    await projectRef.subscribeSource()
                    
                    try! await sourceLink.insert(.init(system: .init(),
                                            user: .init(),
                                            name: testName))
                    try! await sourceLink.processTicket()
                }
            }
            
            // then
            await #expect(projectRef.name == testName)
        }
    }
    
    struct Push {
        let budClientRef: BudClient
        let projectRef: Project
        init() async {
            self.budClientRef = await BudClient()
            self.projectRef = await createAndGetProject(budClientRef)
        }
        
        @Test func whenProjectIsDeleted() async throws {
            // given
            try await #require(projectRef.id.isExist == true)
            
            // when
            await projectRef.push {
                await projectRef.delete()
            }
            
            // then
            let issue = try #require(await projectRef.issue)
            #expect(issue.reason == "projectIsDeleted")
        }
        @Test func whenNameIsNil() async throws {
            // given
            await MainActor.run {
                projectRef.name = nil
            }
            
            // when
            await projectRef.push()
            
            // then
            let issue = try #require(await projectRef.issue)
            #expect(issue.reason == "nameIsNil")
        }
        
        @Test func updateNameByUpdater() async throws {
            // given
            let testName = "TEST_PROJECT_NAME"
            let sourceLink = projectRef.sourceLink
            
            await MainActor.run {
                projectRef.name = testName
            }
            
            // then
            let newTicket = Ticket(system: .init(),
                                   user: .init())
            await withCheckedContinuation { con in
                Task {
                    try! await sourceLink.setHandler(ticket: newTicket,
                                          handler: .init({ event in
                        switch event {
                        case .modified(let newName):
                            #expect(newName == testName)
                            con.resume()
                        }
                    }))
                    
                    // when
                    await projectRef.push()
                }
            }
        }
    }
    
    struct UnsubscribeSource {
        let budClientRef: BudClient
        let projectRef: Project
        init() async {
            self.budClientRef = await BudClient()
            self.projectRef = await createAndGetProject(budClientRef)
            
            await projectRef.setUp()
            await projectRef.subscribeSource()
            
            try! await #require(projectRef.isIssueOccurred == false)
        }
        
        @Test func whenProjectIsDeleted() async throws {
            // given
            try await #require(projectRef.id.isExist == true)
            
            // when
            await projectRef.unsubscribeSource {
                await projectRef.delete()
            }
            
            // then
            let issue = try #require(await projectRef.issue as? KnownIssue)
            #expect(issue.reason == "projectIsDeleted")
        }
        @Test func removeHandlerInProjectSource() async throws {
            // given
            let sourceLink = projectRef.sourceLink
            let system = budClientRef.system
            try await #require(sourceLink.hasHandler(system: system) == true)
            
            // when
            await projectRef.unsubscribeSource()
            
            // then
            try await #expect(sourceLink.hasHandler(system: system) == false)
        }
    }
    

    struct RemoveSource {
        let budClientRef: BudClient
        let projectRef: Project
        init() async {
            self.budClientRef = await BudClient()
            self.projectRef = await createAndGetProject(budClientRef)
        }
        
        @Test func whenProjectIsDeleted() async throws {
            // given
            try await #require(projectRef.id.isExist == true)
            
            // when
            await projectRef.removeSource {
                await projectRef.delete()
            }
            
            // then
            let issue = try #require(await projectRef.issue)
            #expect(issue.reason == "projectIsDeleted")
        }
        
        @Test func removeProjectSource() async throws {
            // given
            let projectSourceLink = projectRef.sourceLink
            
            await #expect(throws: Never.self) {
                let _ = try await projectSourceLink.processTicket()
            }
             
            // when
            await projectRef.removeSource()
            
            // then
            await #expect(throws: ProjectSourceLink.Error.projectSourceDoesNotExist) {
                let _ = try await projectSourceLink.processTicket()
            }
            
        }
        @Test func removeProjectInProjectBoard() async throws {
            // given
            let projectBoardRef = try #require(await projectRef.config.parent.ref)
            try await #require(projectBoardRef.projects.contains(projectRef.id))
            
            // when
            await withCheckedContinuation { con in
                Task {
                    await projectBoardRef.setCallback {
                        con.resume()
                    }
                    
                    await projectBoardRef.subscribeProjectHub()
                    
                    await projectRef.removeSource()
                }
            }
            
            // then
            await #expect(projectBoardRef.projects.contains(projectRef.id) == false)
            
        }
        @Test func updateProjectSourceMapInProjectBoard() async throws {
            // given
            let projectBoardRef = try #require(await projectRef.config.parent.ref)
            try await #require(projectBoardRef.projectSourceMap.count == 1)
            
            // when
            await withCheckedContinuation { con in
                Task {
                    await projectBoardRef.setCallback {
                        con.resume()
                    }
                    
                    await projectBoardRef.subscribeProjectHub()
                    
                    await projectRef.removeSource()
                }
            }
            
            // then
            await #expect(projectBoardRef.projectSourceMap.count == 0)
        }
        @Test func deleteProject() async throws {
            // given
            let projectBoardRef = try #require(await projectRef.config.parent.ref)
            
            // when
            await withCheckedContinuation { con in
                Task {
                    await projectBoardRef.setCallback {
                        con.resume()
                    }
                    
                    await projectBoardRef.subscribeProjectHub()
                    await projectRef.removeSource()
                }
            }
            
            // then
            await #expect(projectRef.id.isExist == false)
        }
    }
}


// MARK: Helphers
