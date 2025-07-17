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
        
        @Test func removeProjectModel() async throws { }
        
        @Test func createSystemModel() async throws {
            // given
            try await #require(systemBoardRef.models.count == 0)
            
            let newSystemSourceMockRef = await SystemSourceMock(
                name: "",
                location: .origin,
                parent: .init()
            )
            let diff = await SystemSourceDiff(newSystemSourceMockRef)
            
            await updaterRef.appendEvent(.added(diff))
            
            // when
            await updaterRef.update()
            
            // then
            try await #require(systemBoardRef.models.count == 1)
            try await #require(updaterRef.queue.isEmpty)
            
            await #expect(systemBoardRef.models.values.first?.isExist == true)
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
    return try #require(await projectBoardRef.projects.first?.ref)
}




