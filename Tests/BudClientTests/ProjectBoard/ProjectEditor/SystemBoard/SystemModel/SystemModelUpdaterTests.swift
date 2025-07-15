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
        let updaterRef: SystemModelUpdater
        let systemModelRef: SystemModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.updaterRef = try await getSystemModelUpdater(budClientRef)
            self.systemModelRef = await updaterRef.config.parent.ref!
        }
        
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
        
        @Test func deleteObjectModel() async throws {
            // given
            let systemSource = try #require(systemModelRef.source as? SystemSourceMock.ID)
            let systemSourceRef = try #require(await systemSource.ref)
            
            let diff = await ObjectSourceDiff(.init(name: "TEST",
                                                    parentRef: systemSourceRef))
            
            // given
            await updaterRef.appendEvent(.added(diff))
            await updaterRef.update()
            
            try await #require(systemModelRef.objectModels.count == 1)
            let objectModel = try #require(await systemModelRef.objectModels.first)
            
            // when
            await updaterRef.appendEvent(.removed(diff))
            await updaterRef.update()
            
            // then
            await #expect(objectModel.isExist == false)
        }
        @Test func removeObjectModelInSystemModel() async throws {
            // given
            let systemSource = try #require(systemModelRef.source as? SystemSourceMock.ID)
            let systemSourceRef = try #require(await systemSource.ref)
            
            let diff = await ObjectSourceDiff(.init(name: "TEST",
                                                    parentRef: systemSourceRef))
            
            // given
            await updaterRef.appendEvent(.added(diff))
            await updaterRef.update()
            
            try await #require(systemModelRef.objectModels.count == 1)
            let objectModel = try #require(await systemModelRef.objectModels.first)
            
            // when
            await updaterRef.appendEvent(.removed(diff))
            await updaterRef.update()
            
            // then
            await #expect(systemModelRef.objectModels.contains(objectModel) == false)
        }
        @Test func whenAlreadyRemoved() async throws {
            // given
            let systemSource = try #require(systemModelRef.source as? SystemSourceMock.ID)
            let systemSourceRef = try #require(await systemSource.ref)
            
            let diff = await ObjectSourceDiff(.init(name: "TEST",
                                                    parentRef: systemSourceRef))
            
            // when
            await updaterRef.appendEvent(.removed(diff))
            await updaterRef.update()
            
            // then
            let issue = try #require(await updaterRef.issue as? KnownIssue)
            #expect(issue.reason == "alreadyRemoved")
        }
        @Test func removeModifiedEventInQueue() async throws {
            // given
            try await #require(updaterRef.queue.isEmpty)
            
            let systemSource = try #require(systemModelRef.source as? SystemSourceMock.ID)
            let systemSourceRef = try #require(await systemSource.ref)
            
            let diff = await ObjectSourceDiff(.init(name: "TEST",
                                                    parentRef: systemSourceRef))
            
            await updaterRef.appendEvent(.modified(diff))
            
            try await #require(updaterRef.queue.count == 1)
            
            // when
            await updaterRef.update()
            
            // then
            await #expect(updaterRef.queue.isEmpty)
        }
        
        @Test func modifyObjectModelName() async throws {
            // given
            let systemSource = try #require(systemModelRef.source as? SystemSourceMock.ID)
            let systemSourceRef = try #require(await systemSource.ref)
            
            let firstName = "FIRST_NAME"
            let diff = await ObjectSourceDiff(.init(name: firstName,
                                                    parentRef: systemSourceRef))
            
            await updaterRef.appendEvent(.added(diff))
            await updaterRef.update()
            
            let objectModelRef = try #require(await systemModelRef.objectModels.first?.ref)
            await #expect(objectModelRef.name == firstName)
            
            // when
            let newName = "NEW_NAME"
            let newDiff = ObjectSourceDiff(id: diff.id,
                                           target: diff.target,
                                           name: newName)
            
            await updaterRef.appendEvent(.modified(newDiff))
            await updaterRef.update()
            
            // then
            try await #require(updaterRef.issue == nil)
            await #expect(objectModelRef.name == newName)
            
        }
        @Test func modifyRemovedObjectModel() async throws {
            // given
            let systemSource = try #require(systemModelRef.source as? SystemSourceMock.ID)
            let systemSourceRef = try #require(await systemSource.ref)
            
            let diff = await ObjectSourceDiff(.init(name: "TEST",
                                                    parentRef: systemSourceRef))
            
            // when
            await MainActor.run {
                updaterRef.appendEvent(.modified(diff))
            }
            await updaterRef.update()
            
            // then
            let issue = try #require(await updaterRef.issue as? KnownIssue)
            #expect(issue.reason == "alreadyRemoved")
        }
        @Test func removeRemovedEventInQueue() async throws {
            // given
            try await #require(updaterRef.queue.isEmpty)
            
            let systemSource = try #require(systemModelRef.source as? SystemSourceMock.ID)
            let systemSourceRef = try #require(await systemSource.ref)
            
            let diff = await ObjectSourceDiff(.init(name: "TEST",
                                                    parentRef: systemSourceRef))
            
            await MainActor.run {
                updaterRef.appendEvent(.removed(diff))
            }
            
            try await #require(updaterRef.queue.count == 1)
            
            // when
            await updaterRef.update()
            
            // then
            await #expect(updaterRef.queue.isEmpty)
        }
    }
}


// MARK: Helphers
private func getSystemModelUpdater(_ budClientRef: BudClient) async throws -> SystemModelUpdater {
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
    
    // ProjectEditor.setUp
    await #expect(projectBoardRef.editors.count == 1)
    let projectEditorRef = try #require(await projectBoardRef.editors.first?.ref)
    
    await projectEditorRef.setUp()
    
    // SystemBoard.createFirstSystem
    let systemBoardRef = try #require(await projectEditorRef.systemBoard?.ref)
    
    await withCheckedContinuation { continuation in
        Task {
            await systemBoardRef.setCallback {
                continuation.resume()
            }
            
            await systemBoardRef.subscribe()
            await systemBoardRef.createFirstSystem()
        }
    }
    
    await systemBoardRef.unsubscribe()
    
    // SystemModel and Updater
    let systemModelRef = try #require(await systemBoardRef.models.values.first?.ref)
    return await systemModelRef.updater
}
