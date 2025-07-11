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
        init() async throws {
            self.budClientRef = await BudClient()
            self.editorRef = try await getProjectEditor(budClientRef)
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
        @Test func whenProjectEditorIsDeleted() async throws {
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
        init() async throws {
            self.budClientRef = await BudClient()
            self.editorRef = try await getProjectEditor(budClientRef)
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
                editorRef.nameInput = nil
            }
            
            // when
            await editorRef.pushName()
            
            // then
            let issue = try #require(await editorRef.issue)
            #expect(issue.reason == "nameInputIsNil")
        }
        
        @Test func updateNameByUpdater() async throws {
            // given
            let testName = "TEST_PROJECT_NAME"
            let projectHubRef = try #require(await editorRef.config.budServer.ref?.projectHub.ref)
            
            let randomObject = ObjectID()
            let user = editorRef.config.user
            
            await MainActor.run {
                editorRef.nameInput = testName
            }
            
            // then
            await withCheckedContinuation { con in
                Task {
                    await projectHubRef.setHandler(
                        requester: randomObject,
                        user: user,
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
            
            // then
            await #expect(editorRef.name == testName)
        }
    }

    struct RemoveSource {
        let budClientRef: BudClient
        let editorRef: ProjectEditor
        init() async throws {
            self.budClientRef = await BudClient()
            self.editorRef = try await getProjectEditor(budClientRef)
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
            let projectSource = editorRef.source
            
            await #expect(projectSource.isExist == true)
             
            // when
            await editorRef.removeProject()
            
            // then
            await #expect(projectSource.isExist == false)
        }
        @Test func removeProjectEditorInProjectBoard() async throws {
            // given
            let projectBoardRef = try #require(await editorRef.config.parent.ref)
            try await #require(projectBoardRef.editors.contains(editorRef.id))
            
            // when
            await withCheckedContinuation { con in
                Task {
                    await projectBoardRef.unsubscribe()
                    
                    await projectBoardRef.setCallback { con.resume() }
                    await projectBoardRef.subscribe()
                    await #expect(projectBoardRef.issue == nil)
                    
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
                    await projectBoardRef.unsubscribe()
                    
                    await projectBoardRef.setCallback {
                        con.resume()
                    }
                    
                    await projectBoardRef.subscribe()
                    await #expect(projectBoardRef.issue == nil)
                    
                    await editorRef.removeProject()
                }
            }
            
            // then
            await #expect(editorRef.id.isExist == false)
        }
    }
}


// MARK: Helphers
private func getProjectEditor(_ budClientRef: BudClient) async throws -> ProjectEditor {
    // BudClient.setUp()
    await budClientRef.setUp()
    let authBoard = try #require(await budClientRef.authBoard)
    let authBoardRef = try #require(await authBoard.ref)
    
    // AuthBoard.setUpForms()
    await authBoardRef.setUpForms()
    let signInForm = try #require(await authBoardRef.signInForm)
    let signInFormRef = try #require(await signInForm.ref)
    
    // SignInForm.setUpSignUpForm()
    await signInFormRef.setUpSignUpForm()
    let signUpFormRef = try #require(await signInFormRef.signUpForm?.ref)
    
    // SignUpForm.signUp()
    let testEmail = Email.random().value
    let testPassword = Password.random().value
    await MainActor.run {
        signUpFormRef.email = testEmail
        signUpFormRef.password = testPassword
        signUpFormRef.passwordCheck = testPassword
    }
    
    await signUpFormRef.signUp()
    

    // ProjectBoard.createNewProject
    let projectBoardRef = try #require(await budClientRef.projectBoard?.ref)
    
    await withCheckedContinuation { continuation in
        Task {
            await projectBoardRef.setCallback {
                continuation.resume()
            }
            
            await projectBoardRef.subscribe()
            await projectBoardRef.createNewProject()
        }
    }
    
    await projectBoardRef.unsubscribe()
    
    // ProjectEditor
    await #expect(projectBoardRef.editors.count == 1)
    return try #require(await projectBoardRef.editors.first?.ref)
}
