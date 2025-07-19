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
@Suite("ProjectModelUpdater")
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
        
        @Test func modifyProjectModel() async throws {
            // given
            let newProject = ProjectID()
            let diff = ProjectSourceDiff(
                id: ProjectSourceMock.ID(),
                target: newProject,
                name: "OLD_NAME")
            
            let projectBoardRef = try #require(await projectModelRef.config.parent.ref)
            let projectBoardUpdaterRef = projectBoardRef.updater
            
            await projectBoardUpdaterRef.appendEvent(.added(diff))
            await projectBoardUpdaterRef.update()
            
            let projectModel = try #require(await projectBoardRef.projects[newProject])
            
            // given
            let newName = "NEW_NAME"
            let newDiff = diff.changeName(newName)
            
            // when
            await updaterRef.appendEvent(.modified(newDiff))
            await updaterRef.update()
            
            try await #require(updaterRef.isIssueOccurred == false)
            
            // then
            await #expect(projectModel.ref?.name == newName)
        }
        
        @Test func removeProjectModelWhenAlreadyRemoved() async throws {
            // given
            await updaterRef.appendEvent(.removed)
            await updaterRef.update()
            
            try await #require(projectModelRef.id.isExist == false)
            
            // when
            await updaterRef.appendEvent(.removed)
            await updaterRef.update()
            
            // then
            let issue = try #require(await updaterRef.issue as? KnownIssue)
            #expect(issue.reason == "projectModelIsDeleted")
        }
        @Test func removeProjectModel() async throws {
            // given
            await updaterRef.appendEvent(.removed)
            
            // when
            await updaterRef.update()
            
            // then
            try await #require(updaterRef.isIssueOccurred == false)
            await #expect(projectModelRef.id.isExist == false)
        }
        @Test func removeSystemModels() async throws {
            // given
            try await #require(projectModelRef.systems.count == 0)
            
            await projectModelRef.startUpdating()
            await withCheckedContinuation { continuation in
                Task {
                    await projectModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await projectModelRef.createSystem()
                }
            }
            
            try await #require(projectModelRef.systems.count == 1)
            
            // when
            await updaterRef.appendEvent(.removed)
            await updaterRef.update()
            
            // then
            for systemModel in await projectModelRef.systems.values {
                await #expect(systemModel.isExist == false)
            }
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
        @Test func createSystemModelWhenAlreadyAdded() async throws {
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




