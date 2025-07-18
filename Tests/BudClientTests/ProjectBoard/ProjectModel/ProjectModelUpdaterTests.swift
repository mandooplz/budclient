//
//  ProjectModelUpdaterTests.swift
//  BudClient
//
//  Created by 김민우 on 7/17/25.
//
import Foundation
import Testing
import Values
@testable import BudClient
@testable import BudServer


// MARK: Tests
@Suite("ProjectModel.Updater")
struct ProjectModelUpdaterTests {
    struct Update {
        let budClientRef: BudClient
        let projectModelRef: ProjectModel
        let updaterRef: ProjectModel.Updater
        init() async throws {
            self.budClientRef = await BudClient()
            self.projectModelRef = try await getProjectModel(budClientRef)
            self.updaterRef = projectModelRef.updaterRef
        }
        
        @Test func modifyProjectModel() async throws { }
        
        @Test func whenProjectModelAlreadyRemoved() async throws {
            // given
            let unknownDiff = ProjectSourceDiff(id: ProjectSourceMock.ID(),
                                                target: .init(),
                                                name: "UNKNOWN_PROJECT")
            
            // when
            await updaterRef.appendEvent(.removed(unknownDiff))
            await updaterRef.update()
            
            // then
            let issue = try #require(await updaterRef.issue as? KnownIssue)
            #expect(issue.reason == "alreadyRemoved")
        }
        @Test func removeProjectModel() async throws {
            // given
            let projectBoardRef = try #require(await projectModelRef.config.parent.ref)
            
            try await #require(projectBoardRef.projects.isEmpty == true)
            
            await projectBoardRef.startUpdating()
            await withCheckedContinuation { continuation in
                Task {
                    await projectBoardRef.setCallback {
                        continuation.resume()
                    }

                    await projectBoardRef.createProject()
                }
            }
            await projectBoardRef.setCallbackNil()
            
            try await #require(projectBoardRef.projects.count == 1)
            
            let projectModel = try #require(await projectBoardRef.projects.values.first)
            let projectModelRef = try #require(await projectModel.ref)
            
            // given
            let diff = ProjectSourceDiff(id: projectModelRef.source,
                                         target: projectModelRef.target,
                                         name: "")
            
            // when
            await updaterRef.appendEvent(.removed(diff))
            await updaterRef.update()
            
            // then
            try await #require(projectBoardRef.issue == nil)
            
            await #expect(projectBoardRef.projects.isEmpty == true)
            await #expect(projectModel.isExist == false)
        }
        
        @Test func createSystemModel() async throws {
            // given
            try await #require(projectModelRef.systems.count == 0)
            
            let diff = SystemSourceDiff(
                id: SystemSourceMock.ID(),
                target: .init(),
                name: "TEST_NAME",
                location: .init(x: 999, y: 999))
            
            await updaterRef.appendEvent(.added(diff))
            
            // when
            await updaterRef.update()
            
            // then
            try await #require(projectModelRef.systems.count == 1)
            try await #require(updaterRef.queue.isEmpty)
            
            await #expect(projectModelRef.systems.values.first?.isExist == true)
        }
        @Test func whenAlreadyAdded() async throws {
            // given
            let newSystemSourceMockRef = await SystemSourceMock(
                name: "",
                location: .origin,
                parent: .init()
            )
            let diff = await SystemSourceDiff(newSystemSourceMockRef)
            
            await updaterRef.appendEvent(.added(diff))
            await updaterRef.update()
            
            // when
            await updaterRef.appendEvent(.added(diff))
            await updaterRef.update()
            
            // then
            try await #require(updaterRef.queue.isEmpty)
            
            let issue = try #require(await updaterRef.issue as? KnownIssue)
            #expect(issue.reason == "alreadyAdded")
        }
    }
}


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
            
            await projectBoardRef.startUpdating()
            await projectBoardRef.createProject()
        }
    }
    
    await projectBoardRef.setCallbackNil()
    
    // ProjectEditor
    await #expect(projectBoardRef.projects.count == 1)
    return try #require(await projectBoardRef.projects.values.first?.ref)
}




