//
//  ProjectTests.swift
//  BudClient
//
//  Created by 김민우 on 7/1/25.
//
import Foundation
import Testing
import Values
@testable import BudClient
@testable import BudServer


// MARK: Tests
@Suite("ProjectEditor", .timeLimit(.minutes(1)))
struct ProjectEditorTests {
    struct SetUp {
        let budClientRef: BudClient
        let editorRef: ProjectEditor
        init() async {
            self.budClientRef = await BudClient()
            self.editorRef = await createAndGetProject(budClientRef)
        }
        
        @Test func wnenAlreadtSetUp() async throws {
            // given
            await editorRef.setUp()
            let updater = try #require(await editorRef.updater)
            let systemBoard = try #require(await editorRef.systemBoard)
            let flowBoard = try #require(await editorRef.flowBoard)
            
            // when
            await editorRef.setUp()
            
            // then
            let issue = try #require(await editorRef.issue as? KnownIssue)
            #expect(issue.reason == "alreadySetUp")
            
            let newUpdater = try #require(await editorRef.updater)
            #expect(newUpdater == updater)
            
            let newSystemBoard = try #require(await editorRef.systemBoard)
            #expect(newSystemBoard == systemBoard)
            
            let newFlowBoard = try #require(await editorRef.flowBoard)
            #expect(newFlowBoard == flowBoard)
        }
        @Test func whenProjectIsDeletedBeforeMutate() async throws {
            // given
            try await #require(editorRef.id.isExist == true)
            
            // when
            await editorRef.setUp {
                await editorRef.delete()
            }
            
            // then
            let issue = try #require(await editorRef.issue as? KnownIssue)
            #expect(issue.reason == "editorIsDeleted")
        }
        
        @Test func createProjectUpdater() async throws {
            // given
            try await #require(editorRef.updater == nil)
            
            // when
            await editorRef.setUp()
            
            // then
            let updater = try #require(await editorRef.updater)
            await #expect(updater.isExist == true)
        }
        @Test func createSystemBoard() async throws {
            // given
            try await #require(editorRef.systemBoard == nil)
            
            // when
            await editorRef.setUp()
            
            // then
            let systemBoard = try #require(await editorRef.systemBoard)
            await #expect(systemBoard.isExist == true)
        }
        @Test func createFlowBoard() async throws {
            // given
            try await #require(editorRef.flowBoard == nil)
            
            // when
            await editorRef.setUp()
            
            // then
            let flowBoard = try #require(await editorRef.flowBoard)
            await #expect(flowBoard.isExist == true)
        }
    }
    
    struct Subscribe {
        let budClientRef: BudClient
        let editorRef: ProjectEditor
        init() async {
            self.budClientRef = await BudClient()
            self.editorRef = await createAndGetProject(budClientRef)
        }
        
        @Test func whenProjectIsDeletedBeforeCapture() async throws {
            // given
            try await #require(editorRef.id.isExist == true)
            
            // when
            await editorRef.subscribe {
                await editorRef.delete()
            }
            
            // then
            let issue = try #require(await editorRef.issue as? KnownIssue)
            #expect(issue.reason == "editorIsDeleted")
        }
        @Test func whenUpdaterIsNil() async throws {
            // given
            try await #require(editorRef.updater == nil)
            
            // when
            await editorRef.subscribe()
            
            // then
            let issue = try #require(await editorRef.issue as? KnownIssue)
            #expect(issue.reason == "updaterIsNil")
        }
        
        @Test func setHandlerInProjectSource() async throws {
            // given
            let sourceLink = editorRef.sourceLink
            let object = await ObjectID(editorRef.id.value)
            try await #require(sourceLink.hasHandler(object: object) == false)
            
            await editorRef.setUp()
            
            // when
            await editorRef.subscribe()
            
            // then
            await #expect(sourceLink.hasHandler(object: object) == true)
        }
        @Test func getUpdateFromProjectSource() async throws {
            // given
            let sourceLink = editorRef.sourceLink
            let testName = "JUST_TEST_NAME"
            
            try await #require(editorRef.name != testName)
            await editorRef.setUp()
            
            // when
            await withCheckedContinuation { con in
                Task {
                    await editorRef.setCallback {
                        con.resume()
                    }
                    
                    await editorRef.subscribe()
                    
                    let editTicket = EditProjectSourceName(testName)
                    try! await sourceLink.insert(editTicket)
                    try! await sourceLink.editProjectName()
                }
            }
            
            // then
            await #expect(editorRef.name == testName)
        }
    }
    
    struct Push {
        let budClientRef: BudClient
        let editorRef: ProjectEditor
        init() async {
            self.budClientRef = await BudClient()
            self.editorRef = await createAndGetProject(budClientRef)
        }
        
        @Test func whenProjectIsDeleted() async throws {
            // given
            try await #require(editorRef.id.isExist == true)
            
            // when
            await editorRef.push {
                await editorRef.delete()
            }
            
            // then
            let issue = try #require(await editorRef.issue)
            #expect(issue.reason == "editorIsDeleted")
        }
        @Test func whenNameIsNil() async throws {
            // given
            await MainActor.run {
                editorRef.name = nil
            }
            
            // when
            await editorRef.push()
            
            // then
            let issue = try #require(await editorRef.issue)
            #expect(issue.reason == "nameIsNil")
        }
        
        @Test func updateNameByUpdater() async throws {
            // given
            let testName = "TEST_PROJECT_NAME"
            let sourceLink = editorRef.sourceLink
            let randomObject = ObjectID()
            let target = editorRef.target
            
            await MainActor.run {
                editorRef.name = testName
            }
            
            // then
            let subscribeTicket = SubscrieProjectSource(object: randomObject, target: target)
  
            await withCheckedContinuation { con in
                Task {
                    await sourceLink.setHandler(ticket: subscribeTicket,
                                          handler: .init({ event in
                        switch event {
                        case .modified(let newName):
                            #expect(newName == testName)
                            con.resume()
                        default:
                            Issue.record()
                        }
                    }))
                    
                    // when
                    await editorRef.push()
                }
            }
        }
    }
    
    struct UnSubscribe {
        let budClientRef: BudClient
        let editorRef: ProjectEditor
        init() async {
            self.budClientRef = await BudClient()
            self.editorRef = await createAndGetProject(budClientRef)
            
            await editorRef.setUp()
            await editorRef.subscribe()
            
            try! await #require(editorRef.isIssueOccurred == false)
        }
        
        @Test func whenProjectIsDeleted() async throws {
            // given
            try await #require(editorRef.id.isExist == true)
            
            // when
            await editorRef.unsubscribe {
                await editorRef.delete()
            }
            
            // then
            let issue = try #require(await editorRef.issue as? KnownIssue)
            #expect(issue.reason == "editorIsDeleted")
        }
        @Test func removeHandlerInProjectSource() async throws {
            // given
            let sourceLink = editorRef.sourceLink
            let me = await ObjectID(editorRef.id.value)
            
            try await #require(sourceLink.hasHandler(object: me) == true)
            
            // when
            await editorRef.unsubscribe()
            
            // then
            await #expect(sourceLink.hasHandler(object: me) == false)
        }
    }
    

    struct RemoveSource {
        let budClientRef: BudClient
        let editorRef: ProjectEditor
        init() async {
            self.budClientRef = await BudClient()
            self.editorRef = await createAndGetProject(budClientRef)
        }
        
        @Test func whenProjectIsDeleted() async throws {
            // given
            try await #require(editorRef.id.isExist == true)
            
            // when
            await editorRef.removeProject {
                await editorRef.delete()
            }
            
            // then
            let issue = try #require(await editorRef.issue)
            #expect(issue.reason == "editorIsDeleted")
        }
        
        @Test func removeProjectSource() async throws {
            // given
            let projectSourceLink = editorRef.sourceLink
            
            await #expect(projectSourceLink.isExist() == true)
             
            // when
            await editorRef.removeProject()
            
            // then
            await #expect(projectSourceLink.isExist() == false)
        }
        @Test func removeProjectInProjectBoard() async throws {
            // given
            let projectBoardRef = try #require(await editorRef.config.parent.ref)
            try await #require(projectBoardRef.editors.contains(editorRef.id))
            
            // when
            await withCheckedContinuation { con in
                Task {
                    await projectBoardRef.setCallback {
                        con.resume()
                    }
                    
                    await projectBoardRef.subscribe()
                    
                    await editorRef.removeProject()
                }
            }
            
            // then
            await #expect(projectBoardRef.editors.contains(editorRef.id) == false)
            
        }
        @Test func deleteProject() async throws {
            // given
            let projectBoardRef = try #require(await editorRef.config.parent.ref)
            
            // when
            await withCheckedContinuation { con in
                Task {
                    await projectBoardRef.setCallback {
                        con.resume()
                    }
                    
                    await projectBoardRef.subscribe()
                    await editorRef.removeProject()
                }
            }
            
            // then
            await #expect(editorRef.id.isExist == false)
        }
    }
}


// MARK: Helphers
