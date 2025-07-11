//
//  SystemBoardUpdaterTests.swift
//  BudClient
//
//  Created by 김민우 on 7/8/25.
//
import Foundation
import Testing
import Values
@testable import BudClient
@testable import BudServer


// MARK: Tests
@Suite("SystemBoardUpdater")
struct SystemBoardUpdaterTests {
    struct Update {
        let budClientRef: BudClient
        let updaterRef: SystemBoardUpdater
        let systemBoardRef: SystemBoard
        init() async throws {
            self.budClientRef = await BudClient()
            self.updaterRef = try await getSystemBoard(budClientRef).updater
            self.systemBoardRef = await updaterRef.config.parent.ref!
        }
        
        @Test func createSystemModel() async throws {
            // given
            try await #require(systemBoardRef.models.count == 0)
            
            let newSystemSource = SystemSourceMock.ID()
            let newSystem = SystemID()
            
            let diff = SystemSourceDiff(id: newSystemSource,
                                        target: newSystem,
                                        name: "",
                                        location: .init(x: 999, y: 999))
            
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
            let newSystemSource = SystemSourceMock.ID()
            let newSystem = SystemID()
            
            let diff = SystemSourceDiff(id: newSystemSource,
                                        target: newSystem,
                                        name: "",
                                        location: .init(x: 999, y: 999))
            
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
        
        @Test func deleteSystemModel() async throws {
            // given
            let newSystemSource = SystemSourceMock.ID()
            let newSystem = SystemID()
            
            let diff = SystemSourceDiff(id: newSystemSource,
                                        target: newSystem,
                                        name: "",
                                        location: .init(x: 999, y: 999))
            
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
private func getSystemBoard(_ budClientRef: BudClient) async throws -> SystemBoard {
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
    
    // SystemBoard
    let systemBoardRef = try #require(await projectEditorRef.systemBoard?.ref)
    return systemBoardRef
}
