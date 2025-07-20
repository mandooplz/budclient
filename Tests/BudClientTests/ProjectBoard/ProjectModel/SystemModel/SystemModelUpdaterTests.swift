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

private let logger = BudLogger("SystemModelUpdaterTest")


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
            self.updaterRef = systemModelRef.updaterRef
        }

        @Test func createObjectModel() async throws {
            // given
            try await #require(systemModelRef.objects.isEmpty)
            
            let diff = ObjectSourceDiff(
                id: ObjectSourceMock.ID(),
                target: .init(),
                name: "TEST_NAME",
                role: .node)
            
            // when
            await updaterRef.appendEvent(.objectAdded(diff))
            await updaterRef.update()
            
            // then
            await #expect(systemModelRef.objects.count == 1)
            
            let objectModelRef = try #require(await systemModelRef.objects.values.first?.ref)
            await #expect(objectModelRef.name == "TEST_NAME")
        }
        @Test func whenAlreadyAdded() async throws {
            // given
            try await #require(systemModelRef.objects.isEmpty)
            
            let diff = ObjectSourceDiff(
                id: ObjectSourceMock.ID(),
                target: .init(),
                name: "TEST_NAME",
                role: .node)
            
            await updaterRef.appendEvent(.objectAdded(diff))
            await updaterRef.update()
            
            try await #require(systemModelRef.objects.count == 1)
            
            // when
            await updaterRef.appendEvent(.objectAdded(diff))
            await updaterRef.update()
            
            // then
            let issue = try #require(await updaterRef.issue as? KnownIssue)
            #expect(issue.reason == "alreadyAdded")
        }
        @Test func removeAddedEventInQueue() async throws {
            // given
            try await #require(updaterRef.queue.isEmpty == true)
            
            let diff = ObjectSourceDiff(
                id: ObjectSourceMock.ID(),
                target: .init(),
                name: "TEST_NAME",
                role: .node)
            
            await updaterRef.appendEvent(.objectAdded(diff))
            
            try await #require(updaterRef.queue.count == 1)
            
            // when
            await updaterRef.update()
            
            // then
            await #expect(updaterRef.queue.isEmpty == true)
        }
        
        @Test func deleteSystemModel() async throws {
            // given
            try await #require(systemModelRef.id.isExist == true)
            
            // when
            await updaterRef.appendEvent(.removed)
            await updaterRef.update()
            
            // then
            try await #require(updaterRef.queue.isEmpty)
            
            await #expect(systemModelRef.id.isExist == false)
        }
        @Test func whenAlreadyRemoved() async throws {
            // given
            await updaterRef.appendEvent(.removed)
            await updaterRef.update()
            
            // when
            await updaterRef.appendEvent(.removed)
            await updaterRef.update()
            
            // then
            let issue = try #require(await updaterRef.issue as? KnownIssue)
            #expect(issue.reason == "systemModelIsDeleted")
        }
        
        @Test func modifyNameOfSystemModel() async throws {
            // given
            let projectModelRef = try #require(await systemModelRef.config.parent.ref)
            let projectModelUpdaterRef = projectModelRef.updaterRef
            
            let diff = SystemSourceDiff(id: SystemSourceMock.ID(),
                                        target: SystemID(),
                                        name: "",
                                        location: .init(x: 99, y: 99))
            
            await projectModelUpdaterRef.appendEvent(.added(diff))
            await projectModelUpdaterRef.update()
            
            let systemModelRef = try #require(await projectModelRef.systems[diff.target]?.ref)
            
            // when
            let newName = "NEW_NAME"
            let newDiff = diff.newName(newName)
            
            await updaterRef.appendEvent(.modified(newDiff))
            await updaterRef.update()
            
            // then
            await #expect(systemModelRef.name == newName)
        }
        @Test func modifyLocationOfSystemModel() async throws {
            // given
            let projectModelRef = try #require(await systemModelRef.config.parent.ref)
            let projectModelUpdaterRef = projectModelRef.updaterRef
            
            let diff = SystemSourceDiff(id: SystemSourceMock.ID(),
                                        target: SystemID(),
                                        name: "",
                                        location: .init(x: 99, y: 99))
            
            await projectModelUpdaterRef.appendEvent(.added(diff))
            await projectModelUpdaterRef.update()
            
            let systemModelRef = try #require(await projectModelRef.systems[diff.target]?.ref)
            
            // when
            let newLocation = Location(x: 999, y: 999)
            let newDiff = diff.newLocation(newLocation)
            
            await updaterRef.appendEvent(.modified(newDiff))
            await updaterRef.update()
            
            // then
            await #expect(systemModelRef.location == newLocation)
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
            await projectBoardRef.startUpdating()
            
            await projectBoardRef.setCallback {
                continuation.resume()
            }
            
            await projectBoardRef.createProject()
        }
    }
    
    
    // ProjectModel.createFirstSystem
    await #expect(projectBoardRef.projects.count == 1)
    let projectModelRef = try #require(await projectBoardRef.projects.values.first?.ref)
    
    await withCheckedContinuation { continuation in
        Task {
            await projectModelRef.startUpdating()
            
            await projectModelRef.setCallback {
                continuation.resume()
            }
            
            await projectModelRef.createFirstSystem()
        }
    }
    
    
    // SystemModel and Updater
    let systemModelRef = try #require(await projectModelRef.systems.values.first?.ref)
    
    logger.end("테스트 준비 끝")
    return systemModelRef
}
