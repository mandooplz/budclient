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
            self.editorRef = await getProject(budClientRef)
        }
        
        @Test func wnenAlreadySetUp() async throws {
            // given
            await editorRef.setUp()
            let systemBoard = try #require(await editorRef.systemBoard)
            let flowBoard = try #require(await editorRef.flowBoard)
            
            // when
            await editorRef.setUp()
            
            // then
            let issue = try #require(await editorRef.issue as? KnownIssue)
            #expect(issue.reason == "alreadySetUp")
            
            let newSystemBoard = try #require(await editorRef.systemBoard)
            #expect(newSystemBoard == systemBoard)
            
            let newFlowBoard = try #require(await editorRef.flowBoard)
            #expect(newFlowBoard == flowBoard)
        }
        @Test func whenProjectEditorIsDeletedBeforeMutate() async throws {
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
        @Test func createValueBoard() async throws {
            // given
            try await #require(editorRef.valueBoard == nil)
            
            // when
            await editorRef.setUp()
            
            // then
            let valueBoard = try #require(await editorRef.valueBoard)
            await #expect(valueBoard.isExist == true)
        }
    }
    
    struct PushName {
        let budClientRef: BudClient
        let editorRef: ProjectEditor
        init() async {
            self.budClientRef = await BudClient()
            self.editorRef = await getProject(budClientRef)
        }
        
        @Test func whenProjectEditorIsDeleted() async throws {
            // given
            try await #require(editorRef.id.isExist == true)
            
            // when
            await editorRef.pushName {
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
            await editorRef.pushName()
            
            // then
            let issue = try #require(await editorRef.issue)
            #expect(issue.reason == "nameIsNil")
        }
        
        @Test func updateNameByUpdater() async throws {
            // given
            let testName = "TEST_PROJECT_NAME"
            let projectHubLink = await editorRef.config.budServerLink.getProjectHub()
            let randomObject = ObjectID()
            
            await MainActor.run {
                editorRef.name = testName
            }
            
            // then
            let ticket = SubscribeProjectHub(object: randomObject,
                                             user: .init())
  
            await withCheckedContinuation { con in
                Task {
                    await projectHubLink.setHandler(
                        ticket: ticket,
                        handler: .init({ event in
                            switch event {
                            case .modified(let diff):
                                #expect(diff.name == testName)
                                con.resume()
                            default:
                                Issue.record()
                            }
                        }))
                    
                    // when
                    await editorRef.pushName()
                }
            }
        }
    }

    struct RemoveSource {
        let budClientRef: BudClient
        let editorRef: ProjectEditor
        init() async {
            self.budClientRef = await BudClient()
            self.editorRef = await getProject(budClientRef)
        }
        
        @Test func whenProjectEditorIsDeleted() async throws {
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
        @Test func removeProjectEditorInProjectBoard() async throws {
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
        @Test func deleteProjectEditor() async throws {
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
