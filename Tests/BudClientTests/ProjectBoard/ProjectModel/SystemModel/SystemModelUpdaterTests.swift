//
//  SystemModelUpdaterTests.swift
//  BudClient
//
//  Created by 김민우 on 7/15/25.
//
import Foundation
import Testing
import Values
@testable import BudClient
@testable import BudServer


// MARK: Tests
@Suite("SystemModelUpdater")
struct SystemModelUpdaterTests {
    struct Update {
        let budClientRef: BudClient
        let systemModelRef: SystemModel
        let updaterRef: SystemModel.Updater
        init() async throws {
            self.budClientRef = await BudClient()
            self.systemModelRef = try await getSystemModel(budClientRef)
            self.updaterRef = systemModelRef.updater
        }

        
        // ObjectSourceDiff.role에 따라 다르게 처리해야하는 거 아닌가?
        @Test func createObjectModel() async throws {
            // given
            try await #require(systemModelRef.objectModels.isEmpty)
            
            let systemSource = try #require(systemModelRef.source as? SystemSourceMock.ID)
            let systemSourceRef = try #require(await systemSource.ref)
            
            let testName = "TEST_NAME"
            let diff = await ObjectSourceDiff(.init(name: testName,
                                                    parentRef: systemSourceRef))
            
            // when
            await updaterRef.appendEvent(.added(diff))
            await updaterRef.update()
            
            // then
            await #expect(systemModelRef.objectModels.count == 1)
            
            let objectModelRef = try #require(await systemModelRef.objectModels.first?.ref)
            await #expect(objectModelRef.name == testName)
        }
        @Test func whenAlreadyAdded() async throws {
            // given
            try await #require(systemModelRef.objectModels.isEmpty)
            
            let systemSource = try #require(systemModelRef.source as? SystemSourceMock.ID)
            let systemSourceRef = try #require(await systemSource.ref)
            
            let diff = await ObjectSourceDiff(.init(name: "TEST",
                                                    parentRef: systemSourceRef))
            
            await updaterRef.appendEvent(.added(diff))
            await updaterRef.update()
            
            // when
            await MainActor.run {
                updaterRef.appendEvent(.added(diff))
            }
            await updaterRef.update()
            
            // then
            let issue = try #require(await updaterRef.issue as? KnownIssue)
            #expect(issue.reason == "alreadyAdded")
        }
        @Test func removeAddedEventInQueue() async throws {
            // given
            try await #require(updaterRef.queue.isEmpty == true)
            
            let systemSource = try #require(systemModelRef.source as? SystemSourceMock.ID)
            let systemSourceRef = try #require(await systemSource.ref)
            
            let diff = await ObjectSourceDiff(.init(name: "TEST",
                                                    parentRef: systemSourceRef))
            
            await updaterRef.appendEvent(.added(diff))
            try await #require(updaterRef.queue.count == 1)
            
            // when
            await updaterRef.update()
            
            // then
            await #expect(updaterRef.queue.isEmpty == true)
        }
        
        @Test func deleteSystemModel() async throws {
            // given
            let newSystemSourceMockRef = await SystemSourceMock(
                name: "",
                location: .origin,
                parent: .init()
            )
            let diff = await SystemSourceDiff(newSystemSourceMockRef)
            
            await updaterRef.appendEvent(.added(diff))
            await updaterRef.update()
            
            try await #require(systemBoardRef.models.count == 1)
            let systemModel = try #require(await systemBoardRef.models.values.first)
            try await #require(systemModel.isExist == true)
            
            // when
            await updaterRef.appendEvent(.removed(diff))
            await updaterRef.update()
            
            // then
            try await #require(updaterRef.queue.isEmpty)
            
            await #expect(systemModel.isExist == false)
            await #expect(systemBoardRef.models.values.contains(systemModel) == false)
        }
        @Test func whenAlreadyRemoved() async throws {
            // given
            let newSystemSource = SystemSourceMock.ID()
            let diff = SystemSourceDiff(id: newSystemSource,
                                        target: .init(),
                                        name: "",
                                        location: .init(x: 1, y: 1))
            
            await updaterRef.appendEvent(.removed(diff))
            
            // when
            await updaterRef.update()
            
            // then
            try await #require(updaterRef.queue.isEmpty)
            
            let issue = try #require(await updaterRef.issue as? KnownIssue)
            #expect(issue.reason == "alreadyRemoved")
        }
        
        @Test func modifySystemModel() async throws {
            // given
            let newSystemSource = SystemSourceMock.ID()
            let newSystem = SystemID()
            
            let diff = SystemSourceDiff(id: newSystemSource,
                                        target: newSystem,
                                        name: "",
                                        location: .init(x: 88, y: 88))
            
            await updaterRef.appendEvent(.added(diff))
            await updaterRef.update()
            
            let systemModelRef = try #require(await systemBoardRef.models.values.first?.ref)
            
            // when
            let testName = "TEST_Name"
            let testLocation = Location(x: 999, y: 999)
            
            let newDiff = SystemSourceDiff(id: newSystemSource,
                                           target: newSystem,
                                           name: testName,
                                           location: testLocation)
            
            await updaterRef.appendEvent(.modified(newDiff))
            await updaterRef.update()
            
            // then
            await #expect(systemModelRef.name == testName)
            await #expect(systemModelRef.location == testLocation)
        }
        @Test func modifySystemModelWhenAlreadyRemoved() async throws {
            // given
            let newSystemSource = SystemSourceMock.ID()
            let diff = SystemSourceDiff(id: newSystemSource,
                                        target: .init(),
                                        name: "",
                                        location: .init(x: 88, y: 88))

            // when
            await updaterRef.appendEvent(.modified(diff))
            await updaterRef.update()
            
            // then
            let issue = try #require(await updaterRef.issue as? KnownIssue)
            #expect(issue.reason == "alreadyRemoved")
        }
    }
}


// MARK: Helphers
private func getSystemModel(_ budClientRef: BudClient) async throws -> SystemModel {
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
            await projectBoardRef.startUpdating()
            
            await projectBoardRef.setCallback {
                continuation.resume()
            }
            
            await projectBoardRef.createProject()
        }
    }
    
    await projectBoardRef.setCallbackNil()
    
    // ProjectModel.createSystem
    await #expect(projectBoardRef.projects.count == 1)
    let projectModelRef = try #require(await projectBoardRef.projects.values.first?.ref)
    
    await withCheckedContinuation { continuation in
        Task {
            await projectModelRef.startUpdating()
            
            await projectModelRef.setCallback {
                continuation.resume()
            }
            
            await projectModelRef.createSystem()
        }
    }
    
    await projectModelRef.setCallbackNil()
    
    // SystemModel and Updater
    let systemModelRef = try #require(await projectModelRef.systems.values.first?.ref)
    return systemModelRef
}
