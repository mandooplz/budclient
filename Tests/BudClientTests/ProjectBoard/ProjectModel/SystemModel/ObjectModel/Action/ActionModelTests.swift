//
//  ActionModelTests.swift
//  BudClient
//
//  Created by 김민우 on 7/22/25.
//
import Foundation
import Testing
import Values
@testable import BudClient
@testable import BudServer


// MARK: Tests
@Suite("ActionModel", .timeLimit(.minutes(1)))
struct ActionModelTests {
    struct StartUpdating {
        let budClientRef: BudClient
        let actionModelRef: ActionModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.actionModelRef = try await getActionModel(budClientRef)
        }
        
        @Test func whenActionModelIsDeleted() async throws {
            // given
            try await #require(actionModelRef.id.isExist == true)
            
            await actionModelRef.setCaptureHook {
                await actionModelRef.delete()
            }
            
            // when
            await actionModelRef.startUpdating()
            
            // then
            let issue = try #require(await actionModelRef.issue as? KnownIssue)
            #expect(issue.reason == "actionModelIsDeleted")
        }
        
        @Test func setIsUpdatingTrue() async throws {
            // given
            try await #require(actionModelRef.isUpdating == false)
            
            // when
            await actionModelRef.startUpdating()
            
            // then
            await #expect(actionModelRef.isUpdating == true)
        }
        @Test func whenAlreadyUpdating() async throws {
            // given
            await actionModelRef.startUpdating()
            await #expect(actionModelRef.isUpdating == true)
            
            // when
            await actionModelRef.startUpdating()
            
            // then
            let issue = try #require(await actionModelRef.issue as? KnownIssue)
            #expect(issue.reason == "alreadyUpdating")
        }
    }
    
    struct PushName {
        let budClientRef: BudClient
        let actionModelRef: ActionModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.actionModelRef = try await getActionModel(budClientRef)
        }
        
        @Test func whenActionModelIsDeleted() async throws {
            // given
            try await #require(actionModelRef.id.isExist == true)
            
            await actionModelRef.setCaptureHook {
                await actionModelRef.delete()
            }
            
            // when
            await actionModelRef.pushName()
            
            // then
            let issue = try #require(await actionModelRef.issue as? KnownIssue)
            #expect(issue.reason == "actionModelIsDeleted")
        }
        
        @Test func whenNameInputIsEmpty() async throws {
            // given
            await MainActor.run {
                actionModelRef.nameInput = ""
            }
            
            try await #require(actionModelRef.issue == nil)
            
            // when
            await actionModelRef.pushName()
            
            // then
            let issue = try #require(await actionModelRef.issue as? KnownIssue)
            #expect(issue.reason == "nameCannotBeEmpty")
        }
        @Test func whenNameInputIsSameWithName() async throws {
            // given
            let testName = "TEST_NAME"
            await MainActor.run {
                actionModelRef.name = testName
                actionModelRef.nameInput = testName
            }
            
            try await #require(actionModelRef.issue == nil)
            
            // when
            await actionModelRef.pushName()
            
            // then
            let issue = try #require(await actionModelRef.issue as? KnownIssue)
            #expect(issue.reason == "newNameIsSameAsCurrent")
        }
        
        @Test func updateNamebyUpdater() async throws {
            // given
            let oldName = "OLD_NAME"
            let newName = "NEW_NAME"
            
            await MainActor.run {
                actionModelRef.name = oldName
                actionModelRef.nameInput = newName
            }
            
            await actionModelRef.startUpdating()
            try await #require(actionModelRef.isUpdating == true)
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await actionModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await actionModelRef.pushName()
                }
            }
            
            // then
            try await #require(actionModelRef.issue == nil)
            
            await #expect(actionModelRef.name != oldName)
            await #expect(actionModelRef.name == newName)
        }
    }
    
    struct DuplicateAction {
        let budClientRef: BudClient
        let actionModelRef: ActionModel
        let objectModelRef: ObjectModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.actionModelRef = try await getActionModel(budClientRef)
            self.objectModelRef = try #require(await actionModelRef.config.parent.ref)
        }
        
        @Test func whenActionModelIsDeleted() async throws {
            // given
            try await #require(actionModelRef.id.isExist == true)
            
            await actionModelRef.setCaptureHook {
                await actionModelRef.delete()
            }
            
            // when
            await actionModelRef.duplicateAction()
            
            // then
            let issue = try #require(await actionModelRef.issue as? KnownIssue)
            #expect(issue.reason == "actionModelIsDeleted")
        }
        
        @Test func appendActionModel_ObjectModel() async throws {
            // given
            let oldCount = await objectModelRef.actions.count
            
            // when
            try await duplicateAction(actionModelRef)
            
            // then
            try await #require(actionModelRef.issue == nil)
            
            let newCount = await objectModelRef.actions.count
            
            #expect(newCount == oldCount + 1)
        }
        @Test func createActionModel_ObjectModel() async throws {
            // given
            try await #require(objectModelRef.actions.count == 1)
            
            // when
            try await duplicateAction(actionModelRef)
            
            // then
            let newActionModel = try #require(await objectModelRef.actions.values.last)
            await #expect(newActionModel.isExist == true)
        }
        
        @Test func duplicateName() async throws {
            // given
            let originalName = await actionModelRef.name
            
            try await #require(objectModelRef.actions.count == 1)
            
            // when
            try await duplicateAction(actionModelRef)
            
            // then
            let newActionModelRef = try #require(await objectModelRef.actions.values.last?.ref)
            
            await #expect(newActionModelRef.name == originalName)
        }
    }
    
    struct RemoveAction {
        let budClientRef: BudClient
        let actionModelRef: ActionModel
        let objectModelRef: ObjectModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.actionModelRef = try await getActionModel(budClientRef)
            self.objectModelRef = try #require(await actionModelRef.config.parent.ref)
        }
        
        @Test func whenActionModelIsDeleted() async throws {
            // given
            try await #require(actionModelRef.id.isExist == true)
            
            await actionModelRef.setCaptureHook {
                await actionModelRef.delete()
            }
            
            // when
            await actionModelRef.removeAction()
            
            // then
            let issue = try #require(await actionModelRef.issue as? KnownIssue)
            #expect(issue.reason == "actionModelIsDeleted")
        }
        
        @Test func removeActionModel_StateModel() async throws {
            // given
            try await #require(objectModelRef.actions.values.contains(actionModelRef.id) == true)
            
            // when
            try await removeAction(actionModelRef)
            
            // then
            await #expect(objectModelRef.actions.values.contains(actionModelRef.id) == false)
        }
        @Test func deleteActionModel() async throws {
            // given
            try await #require(actionModelRef.id.isExist == true)
            
            // when
            try await removeAction(actionModelRef)
            
            // then
            await #expect(actionModelRef.id.isExist == false)
        }
    }
}


// MARK: Tests - updater
@Suite("ActionModelUpdater")
struct ActionModelUpdaterTests {
    struct Update {
        let budClientRef: BudClient
        let actionModelRef: ActionModel
        let updaterRef: ActionModel.Updater
        let sourceRef: ActionSourceMock
        init() async throws {
            self.budClientRef = await BudClient()
            self.actionModelRef = try await getActionModel(budClientRef)
            self.updaterRef = actionModelRef.updaterRef
            self.sourceRef = try #require(await actionModelRef.source.ref as? ActionSourceMock)
        }
        
        @Test func whenEventQueueIsEmpty() async throws {
            // given
            try await #require(updaterRef.queue.isEmpty == true)
            
            // when
            await updaterRef.update()
            
            // then
            let issue = try #require(await updaterRef.issue as? KnownIssue)
            #expect(issue.reason == "eventQueueIsEmpty")
        }
        @Test func whenActionModelIsDeleted() async throws {
            // given
            try await #require(actionModelRef.id.isExist == true)
            
            await updaterRef.setCaptureHook {
                await actionModelRef.delete()
            }
            
            // when
            await updaterRef.appendEvent(.removed)
            await updaterRef.update()
            
            // then
            let issue = try #require(await updaterRef.issue as? KnownIssue)
            #expect(issue.reason == "actionModelIsDeleted")
        }
        
        // ActionSourceEvent.modify
        @Test func modifyActionModelName() async throws {
            // given
            let oldName = "OLD_NAME"
            let newName = "NEW_NAME"
            
            await MainActor.run {
                actionModelRef.name = oldName
            }
            
            // given
            await sourceRef.setName(newName)
            
            let diff = await ActionSourceDiff(sourceRef)
            
            // when
            await updaterRef.appendEvent(.modified(diff))
            await updaterRef.update()
            
            // then
            await #expect(actionModelRef.name != oldName)
            await #expect(actionModelRef.name == newName)
        }
        @Test func modifyActionModelNameInput() async throws {
            // given
            let oldName = "OLD_NAME"
            let newName = "NEW_NAME"
            
            await MainActor.run {
                actionModelRef.nameInput = oldName
            }
            
            // given
            await sourceRef.setName(newName)
            
            let diff = await ActionSourceDiff(sourceRef)
            
            // when
            await updaterRef.appendEvent(.modified(diff))
            await updaterRef.update()
            
            // then
            await #expect(actionModelRef.nameInput != oldName)
            await #expect(actionModelRef.nameInput == newName)
        }
        
        // ActionSourceEvent.removed
        @Test func deleteActionModel() async throws {
            // given
            try await #require(actionModelRef.id.isExist == true)
            
            // when
            await updaterRef.appendEvent(.removed)
            await updaterRef.update()
            
            // then
            await #expect(actionModelRef.id.isExist == false)
        }
        @Test func removeActionModel_ObjectModel() async throws {
            // given
            let objectModelRef = try #require(await actionModelRef.config.parent.ref)
            
            try await #require(objectModelRef.actions.values.contains(actionModelRef.id))
            
            // when
            await updaterRef.appendEvent(.removed)
            await updaterRef.update()
            
            // then
            await #expect(objectModelRef.actions.values.contains(actionModelRef.id) == false)
        }
    }
}


// MARK: Helphers
private func getActionModel(_ budClientRef: BudClient) async throws -> ActionModel {
    // create SignInForm
    await budClientRef.setUp()
    let signInForm = try #require(await budClientRef.signInForm)
    let signInFormRef = try #require(await signInForm.ref)
    
    // create SignUpForm
    await signInFormRef.setUpSignUpForm()
    let signUpFormRef = try #require(await signInFormRef.signUpForm?.ref)
    
    // signup
    let testEmail = Email.random().value
    let testPassword = Password.random().value
    await MainActor.run {
        signUpFormRef.email = testEmail
        signUpFormRef.password = testPassword
        signUpFormRef.passwordCheck = testPassword
    }
    
    await signUpFormRef.submit()
    

    // create ProjectModel
    let projectBoardRef = try #require(await budClientRef.projectBoard?.ref)
    
    await projectBoardRef.startUpdating()
    try await #require(projectBoardRef.isUpdating == true)
    
    await withCheckedContinuation { continuation in
        Task {
            await projectBoardRef.setCallback {
                continuation.resume()
            }
            await projectBoardRef.createProject()
        }
    }
    
    await #expect(projectBoardRef.projects.count == 1)

    // create SystemModel
    let projectModelRef = try #require(await projectBoardRef.projects.values.first?.ref)
    
    await projectModelRef.startUpdating()
    try await #require(projectModelRef.isUpdating == true)
    
    await withCheckedContinuation { continuation in
        Task {
            await projectModelRef.setCallback {
                continuation.resume()
            }
            
            await projectModelRef.createFirstSystem()
        }
    }
    
    
    // create RootObject
    let systemModelRef = try #require(await projectModelRef.systems.values.first?.ref)
    await systemModelRef.startUpdating()
    try await #require(systemModelRef.isUpdating == true)
    
    await withCheckedContinuation { continuation in
        Task {
            await systemModelRef.setCallback {
                continuation.resume()
            }
            
            await systemModelRef.createRootObject()
        }
    }
    
    
    // create ActionModel
    let rootObjectModelRef = try #require(await systemModelRef.root?.ref)
    
    await rootObjectModelRef.startUpdating()
    try await #require(rootObjectModelRef.isUpdating == true)
    try await #require(rootObjectModelRef.actions.count == 0)
    
    await withCheckedContinuation { continuation in
        Task {
            await rootObjectModelRef.setCallback {
                continuation.resume()
            }
            
            await rootObjectModelRef.appendNewAction()
        }
    }
    
    try await #require(rootObjectModelRef.actions.count == 1)
    
    return try #require(await rootObjectModelRef.actions.values.first?.ref)
}

private func createNewActionModel(_ objectModelRef: ObjectModel) async throws {
    await objectModelRef.startUpdating()
    try await #require(objectModelRef.isUpdating == true)
    
    await withCheckedContinuation { continuation in
        Task {
            await objectModelRef.setCallback {
                continuation.resume()
            }
            
            await objectModelRef.appendNewAction()
        }
    }
}


// MARK: Helphers - action
private func duplicateAction(_ actionModelRef: ActionModel) async throws {
    let objectModelRef = try #require(await actionModelRef.config.parent.ref)
    
    await actionModelRef.startUpdating()
    try await #require(actionModelRef.isUpdating == true)
    
    await withCheckedContinuation { continuation in
        Task {
            await objectModelRef.setCallback {
                continuation.resume()
            }
            
            await actionModelRef.duplicateAction()
        }
    }
}
private func removeAction(_ actionModelRef: ActionModel) async throws {
    await actionModelRef.startUpdating()
    try await #require(actionModelRef.isUpdating == true)
    
    await withCheckedContinuation { continuation in
        Task {
            await actionModelRef.setCallback {
                continuation.resume()
            }
            
            await actionModelRef.removeAction()
        }
    }
}
