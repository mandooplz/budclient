//
//  ProjectBoardUpdaterTests.swift
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
@Suite("ProjectBoard.Updater", .timeLimit(.minutes(1)))
struct ProjectBoardUpdaterTests {
    struct Update {
        let budClientRef: BudClient
        let projectBoardRef: ProjectBoard
        let updaterRef: ProjectBoard.Updater
        init() async throws {
            self.budClientRef = await BudClient()
            self.projectBoardRef = try await getProjectBoard(budClientRef)
            self.updaterRef = projectBoardRef.updaterRef
        }
        
        @Test func whenProjectModelAlreadyAdded() async throws {
            // given
            await projectBoardRef.startUpdating()
            await projectBoardRef.setCallbackNil()
            await withCheckedContinuation { continuation in
                Task {
                    await projectBoardRef.setCallback {
                        continuation.resume()
                    }
                    
                    await projectBoardRef.createProject()
                }
            }
            
            try await #require(projectBoardRef.projects.count == 1)
            
            let projectEditorRef = try #require(await projectBoardRef.projects.values.first?.ref)
            let projectSourceRef = try #require(await projectEditorRef.source.ref)
            
            // when
            let diff = ProjectSourceDiff(
                id: projectSourceRef.id,
                target: projectEditorRef.target,
                name: "DUPLICATE")
            
            await updaterRef.appendEvent(.added(diff))
            await updaterRef.update()
            
            // then
            await #expect(projectBoardRef.projects.count == 1)
            
            let issue = try #require(await updaterRef.issue as? KnownIssue)
            #expect(issue.reason == "alreadyAdded")
        }
        
        @Test func createProjectModel() async throws {
            // given
            try await #require(projectBoardRef.projects.isEmpty == true)
            
            let newProject = ProjectID()
            let diff = ProjectSourceDiff(id: ProjectSourceMock.ID(),
                                         target: newProject,
                                         name: "")
            
            await updaterRef.appendEvent(.added(diff))
            
            // when
            await updaterRef.update()
            
            // then
            try await #require(updaterRef.issue == nil)
            
            try await #require(projectBoardRef.projects.count == 1)
            let projectModel = try #require(await projectBoardRef.projects.values.first)
            let projectModelRef = try #require(await projectModel.ref)
            
            #expect(projectModelRef.target == newProject)
        }
        @Test func removeEventWhenAdded() async throws {
            // given
            let newProject = ProjectID()
            let newProjectSource = ProjectSourceMock.ID()
            
            let diff = ProjectSourceDiff(id: newProjectSource,
                                         target: newProject,
                                         name: "")
            await updaterRef.appendEvent(.added(diff))
            
            // when
            await updaterRef.update()
            
            // then
            await #expect(updaterRef.queue.isEmpty)
        }
    }
}


// MARK: Helpher
private func getProjectBoard(_ budClientRef: BudClient) async throws -> ProjectBoard {
    // BudClient.setUp()
    await budClientRef.setUp()
    let signInForm = try #require(await budClientRef.signInForm)
    let signInFormRef = try #require(await signInForm.ref)
    
    // SignInForm.setUpSignUpForm()
    await signInFormRef.setUpSignUpForm()
    let signUpFormRef = try #require(await signInFormRef.signUpForm?.ref)
    
    // SignUpForm.submit()
    let testEmail = Email.random().value
    let testPassword = Password.random().value
    await MainActor.run {
        signUpFormRef.email = testEmail
        signUpFormRef.password = testPassword
        signUpFormRef.passwordCheck = testPassword
    }
    
    await signUpFormRef.submit()
    
    // ProjectBoard
    let projectBoardRef = try #require(await budClientRef.projectBoard?.ref)
    return projectBoardRef
}

