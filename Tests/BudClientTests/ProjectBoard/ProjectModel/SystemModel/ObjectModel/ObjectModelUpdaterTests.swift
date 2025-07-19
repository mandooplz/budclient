//
//  ObjectModelUpdaterTests.swift
//  BudClient
//
//  Created by 김민우 on 7/18/25.
//
import Foundation
import Testing
import Values
@testable import BudClient
@testable import BudServer

private let logger = BudLogger("ObjectModelUpdaterTest")

// MARK: Tests
@Suite("ObjectModelUpdater", .timeLimit(.minutes(1)))
struct ObjectModelUpdaterTests {
    struct Update {
        let budClientRef: BudClient
        let objectModelRef: ObjectModel
        let updaterRef: ObjectModel.Updater
        init() async throws {
            self.budClientRef = await BudClient()
            self.objectModelRef = try await getRootObjectModel(budClientRef)
            self.updaterRef = objectModelRef.updaterRef
        }
        
        @Test func deleteObjectModel() async throws {
            // given
            _ = ObjectSourceDiff(
                id: ObjectSourceMock.ID(),
                target: objectModelRef.target,
                name: "TEST_OBJECT",
                role: .node)
            
            // when
            await updaterRef.appendEvent(.removed)
            await updaterRef.update()
            
            // then
            await #expect(objectModelRef.id.isExist == false)
        }
        @Test func removeObjectModelInSystemModel() async throws {
            // given
            let systemModelRef = await objectModelRef.config.parent.ref!
            let target = objectModelRef.target
            
            _ = ObjectSourceDiff(
                id: ObjectSourceMock.ID(),
                target: target,
                name: "TEST_OBJECT",
                role: .node)

            
            try await #require(systemModelRef.objects.count == 1)
            
            // when
            await updaterRef.appendEvent(.removed)
            await updaterRef.update()
            
            // then
            await #expect(systemModelRef.objects[target] == nil)
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
            #expect(issue.reason == "objectModelIsDeleted")
        }
        @Test func removeModifiedEventInQueue() async throws {
            // given
            try await #require(updaterRef.queue.isEmpty)
            
            let diff = ObjectSourceDiff(
                id: ObjectSourceMock.ID(),
                target: .init(),
                name: "TEST_OBJECT",
                role: .node)
            
            await updaterRef.appendEvent(.modified(diff))
            
            try await #require(updaterRef.queue.count == 1)
            
            // when
            await updaterRef.update()
            
            // then
            await #expect(updaterRef.queue.isEmpty)
        }
        
        @Test func modifyObjectModelName() async throws {
            // given
            let objectSourceRef = try #require(await objectModelRef.source.ref as? ObjectSourceMock)
            
            let diff = await ObjectSourceDiff(objectSourceRef)
            
            let newName = "NEW_NAME"
            let newDiff = diff.newName(newName)
            
            // when
            await updaterRef.appendEvent(.modified(newDiff))
            await updaterRef.update()
            
            // then
            try await #require(updaterRef.issue == nil)
            await #expect(objectModelRef.name == newName)
        }
        @Test func modifyRemovedObjectModel() async throws {
            // given
            await objectModelRef.delete()
            
            let diff = ObjectSourceDiff(
                id: objectModelRef.source,
                target: objectModelRef.target,
                name: "",
                role: .node)
            
            // when
            await updaterRef.appendEvent(.modified(diff))
            await updaterRef.update()
            
            // then
            let issue = try #require(await updaterRef.issue as? KnownIssue)
            #expect(issue.reason == "objectModelIsDeleted")
        }
        @Test func removeRemovedEventInQueue() async throws {
            // given
            try await #require(updaterRef.queue.isEmpty)
            
            _ = ObjectSourceDiff(
                id: ObjectSourceMock.ID(),
                target: .init(),
                name: "TEST_OBJECT",
                role: .node)
            
            await updaterRef.appendEvent(.removed)
            
            try await #require(updaterRef.queue.count == 1)
            
            // when
            await updaterRef.update()
            
            // then
            await #expect(updaterRef.queue.isEmpty)
        }
    }
}


// MARK: Helphers
private func getRootObjectModel(_ budClientRef: BudClient) async throws-> ObjectModel {
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
    

    // ProjectBoard.createProject
    let projectBoardRef = try #require(await budClientRef.projectBoard?.ref)
    
    await projectBoardRef.startUpdating()
    await withCheckedContinuation { continuation in
        Task {
            await projectBoardRef.setCallback {
                continuation.resume()
            }
            
            await projectBoardRef.createProject()
        }
    }
    
    await #expect(projectBoardRef.projects.count == 1)

    // ProjectModel.createFirstSystem
    let projectModelRef = try #require(await projectBoardRef.projects.values.first?.ref)
    
    await projectModelRef.startUpdating()
    await withCheckedContinuation { continuation in
        Task {
            await projectModelRef.setCallback {
                continuation.resume()
            }
            
            await projectModelRef.createFirstSystem()
        }
    }
    
    // SystemModel
    let systemModelRef = try #require(await projectModelRef.systems.values.first?.ref)
    await systemModelRef.startUpdating()
    await withCheckedContinuation { continuation in
        Task {
            await systemModelRef.setCallback {
                continuation.resume()
            }
            
            await systemModelRef.createRoot()
        }
    }
    await systemModelRef.setCallbackNil()
    
    let rootObjectModelRef = try #require(await systemModelRef.root?.ref)
    
    logger.end("테스트 준비 끝")
    
    return rootObjectModelRef
}
