//
//  ProjectModelTests.swift
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
@Suite("ProjectModel", .timeLimit(.minutes(1)))
struct ProjectModelTests {
    struct StartUpdating {
        let budClientRef: BudClient
        let projectModelRef: ProjectModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.projectModelRef = try await getProjectModel(budClientRef)
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
        @Test func whenNameInputIsEmpty() async throws {
            // given
            await MainActor.run {
                editorRef.nameInput = ""
            }
            
            // when
            await editorRef.pushName()
            
            // then
            let issue = try #require(await editorRef.issue as? KnownIssue)
            #expect(issue.reason == "nameInputIsEmpty")
        }
        @Test func whenNameInputIsSameWithName() async throws {
            // given
            await MainActor.run {
                editorRef.nameInput = "TEST"
                editorRef.name = "TEST"
            }
            
            // when
            await editorRef.pushName()
            
            // then
            let issue = try #require(await editorRef.issue as? KnownIssue)
            #expect(issue.reason == "pushWithSameValue")
        }
        
        @Test func updateNameByUpdater() async throws {
            // given
            let testName = "TEST_PROJECT_NAME"
            let projectBoardRef = try #require(await editorRef.config.parent.ref)
            
            await MainActor.run {
                editorRef.nameInput = testName
            }
            
            // then
            await withCheckedContinuation { con in
                Task {
                    await projectBoardRef.setCallback {
                        con.resume()
                    }
                    
                    await projectBoardRef.subscribe()
                    
                    // when
                    await editorRef.pushName()
                }
            }
            
            // then
            await projectBoardRef.unsubscribe()
            await #expect(editorRef.name == testName)
        }
    }

    struct RemoveProject {
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
    
    struct CreateFirstSystem { // ProjectModelTests로 이동
        let budClientRef: BudClient
        let systemBoardRef: SystemBoard
        init() async throws {
            self.budClientRef = await BudClient()
            self.systemBoardRef = try await getSystemBoard(budClientRef)
        }
        
        @Test func whenSystemBoardIsDeleted() async throws {
            // given
            try await #require(systemBoardRef.id.isExist == true)
            
            // when
            await systemBoardRef.createFirstSystem {
                await systemBoardRef.delete()
            }
            
            // then
            let issue = try #require(await systemBoardRef.issue as? KnownIssue)
            #expect(issue.reason == "systemBoardIsDeleted")
        }
        @Test func whenSystemAlreadyExist() async throws {
            // given
            await withCheckedContinuation { con in
                Task {
                    await systemBoardRef.setCallback {
                        con.resume()
                    }
                    
                    await systemBoardRef.subscribe()
                    await systemBoardRef.createFirstSystem()
                }
            }
            
            try await #require(systemBoardRef.models.isEmpty == false)
            try await #require(systemBoardRef.issue == nil)
            
            // when
            await systemBoardRef.createFirstSystem()
            
            // then
            let issue = try #require(await systemBoardRef.issue as? KnownIssue)
            #expect(issue.reason == "systemAlreadyExist")
        }
        
        @Test func createSystemModel() async throws {
            // given
            try await #require(systemBoardRef.models.isEmpty == true)
            
            await systemBoardRef.unsubscribe()
            
            // when
            await withCheckedContinuation { con in
                Task {
                    await systemBoardRef.setCallback {
                        con.resume()
                    }
                    await systemBoardRef.subscribe()
                    
                    await systemBoardRef.createFirstSystem()
                }
            }
            
            // then
            try await #require(systemBoardRef.models.count == 1)
            
            let systemModel = try #require(await systemBoardRef.models.values.first)
            await #expect(systemModel.isExist == true)
        }
        @Test func createSystemSource() async throws {
            // given
            let projectEditorRef = try #require(await systemBoardRef.config.parent.ref)
            let projectSourceRef = try #require(await projectEditorRef.source.ref as? ProjectSourceMock)
            
            try await #require(projectSourceRef.systems.isEmpty == true)
            
            // when
            await systemBoardRef.createFirstSystem()
            
            // then
            await #expect(projectSourceRef.systems.count == 1)
        }
    }
}


// MARK: Helphers
private func getProjectModel(_ budClientRef: BudClient) async throws -> ProjectModel {
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
