//
//  ObjectModelTests.swift
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
@Suite("ObjectModel", .timeLimit(.minutes(1)))
struct ObjectModelTests {
    struct StartUpdating {
        let budClientRef: BudClient
        let objectModelRef: ObjectModel
        let objectSourceRef: ObjectSourceMock
        init() async throws {
            self.budClientRef = await BudClient()
            self.objectModelRef = try await getRootObjectModel(budClientRef)
            self.objectSourceRef = await objectModelRef.source.ref as! ObjectSourceMock
        }
        
        @Test func whenObjectModelIsDeleted() async throws {
            // given
            try await #require(objectModelRef.id.isExist == true)
            
            await objectModelRef.setCaptureHook {
                await objectModelRef.delete()
            }
            
            // when
            await objectModelRef.startUpdating()
            
            // then
            let issue = try #require(await objectModelRef.issue as? KnownIssue)
            #expect(issue.reason == "objectModelIsDeleted")
        }
        
        @Test func setIsUpdatingTrue() async throws {
            // given
            try await #require(objectModelRef.isUpdating == false)
            
            // when
            await objectModelRef.startUpdating()
            
            // then
            try await #require(objectModelRef.issue == nil)
            
            await #expect(objectModelRef.isUpdating == true)
        }
        @Test func whenAlreadyUpdating() async throws {
            // given
            await objectModelRef.startUpdating()
            
            try await #require(objectModelRef.issue == nil)
            
            // when
            await objectModelRef.startUpdating()
            
            // then
            let issue = try #require(await objectModelRef.issue as? KnownIssue)
            #expect(issue.reason == "alreadyUpdating")
        }
        
        @Test func receiveInitialEvent_StateAdded() async throws {
            // given
            try await #require(objectSourceRef.states.isEmpty)
            await objectSourceRef.appendNewState()
            try await #require(objectSourceRef.states.count == 1)
            
            try await #require(objectModelRef.states.isEmpty)
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await objectModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await objectModelRef.startUpdating()
                }
            }
            
            // then
            await #expect(objectModelRef.states.count == 1)
        }
        @Test func receiveInitialEvent_ActionAdded() async throws {
            // given
            try await #require(objectSourceRef.actions.isEmpty)
            await objectSourceRef.appendNewAction()
            try await #require(objectSourceRef.actions.count == 1)
            
            try await #require(objectModelRef.actions.isEmpty)
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await objectModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await objectModelRef.startUpdating()
                }
            }
            
            // then
            await #expect(objectModelRef.actions.count == 1)
        }
    }
    
    struct PushName {
        let budClientRef: BudClient
        let objectModelRef: ObjectModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.objectModelRef = try await getRootObjectModel(budClientRef)
        }
        
        @Test func whenObjectModelIsDeleted() async throws {
            // given
            try await #require(objectModelRef.id.isExist == true)
            
            await objectModelRef.setCaptureHook {
                await objectModelRef.delete()
            }
            
            // when
            await objectModelRef.pushName()
            
            // then
            let issue = try #require(await objectModelRef.issue as? KnownIssue)
            #expect(issue.reason == "objectModelIsDeleted")
        }
        
        @Test func whenNameInputIsEmpty() async throws {
            // given
            await MainActor.run {
                objectModelRef.nameInput = ""
            }
            
            // when
            await objectModelRef.pushName()
            
            // then
            let issue = try #require(await objectModelRef.issue as? KnownIssue)
            #expect(issue.reason == "nameCannotBeEmpty")
        }
        @Test func whenNameInputIsSameWithName() async throws {
            // given
            await MainActor.run {
                let testName = "TEST_NAME"
                objectModelRef.nameInput = testName
                objectModelRef.name = testName
            }
            
            // when
            await objectModelRef.pushName()
            
            // then
            let issue = try #require(await objectModelRef.issue as? KnownIssue)
            #expect(issue.reason == "newNameIsSameAsCurrent")
        }
        
        @Test func updateNameByUpdater() async throws {
            // given
            let oldName = "OLD_NAME"
            let newName = "NEW_NAME"
            
            await MainActor.run {
                objectModelRef.name = oldName
                objectModelRef.nameInput = newName
            }
            
            try await #require(objectModelRef.isUpdating == false)
            await objectModelRef.startUpdating()
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await objectModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await objectModelRef.pushName()
                }
            }
            
            // then
            await #expect(objectModelRef.name != oldName)
            await #expect(objectModelRef.name == newName)
        }
    }
    
    struct createChildObject {
        let budClientRef: BudClient
        let objectModelRef: ObjectModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.objectModelRef = try await getRootObjectModel(budClientRef)
        }
        
        @Test func whenObjectModelIsDeleted() async throws {
            // given
            try await #require(objectModelRef.id.isExist == true)
            
            await objectModelRef.setCaptureHook {
                await objectModelRef.delete()
            }
            
            // when
            await objectModelRef.createChildObject()
            
            // then
            let issue = try #require(await objectModelRef.issue as? KnownIssue)
            #expect(issue.reason == "objectModelIsDeleted")
        }
        
        @Test func appendObjectModel_SystemModel() async throws {
            // given
            let systemModelRef = try #require(await objectModelRef.config.parent.ref)
            
            let count = await systemModelRef.objects.count
            
            try await #require(systemModelRef.isUpdating == true)
            try #require(objectModelRef.role == .root)
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await systemModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await objectModelRef.createChildObject()
                }
            }
            
            // then
            await #expect(systemModelRef.objects.count == count + 1)
        }
        @Test func createObjectModel_SystemModel() async throws {
            // given
            let systemModelRef = try #require(await objectModelRef.config.parent.ref)
            
            try await #require(systemModelRef.isUpdating == true)
            try await #require(systemModelRef.objects.count == 1)
            
            try #require(objectModelRef.role == .root)
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await systemModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await objectModelRef.createChildObject()
                }
            }
            
            // then
            try await #require(systemModelRef.objects.count == 2)
            
            let newObjectModel = try #require(await systemModelRef.objects.values.last)
            await #expect(newObjectModel.isExist == true)
        }
        @Test func setNewObjectModelParentToSelfTarget() async throws {
            // given
            let systemModelRef = try #require(await objectModelRef.config.parent.ref)
            
            try await #require(systemModelRef.isUpdating == true)
            try await #require(systemModelRef.objects.count == 1)
            
            try #require(objectModelRef.role == .root)
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await systemModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await objectModelRef.createChildObject()
                }
            }
            
            // then
            try await #require(systemModelRef.objects.count == 2)
            
            let newObjectModelRef = try #require(await systemModelRef.objects.values.last?.ref)
            
            await #expect(newObjectModelRef.parent == objectModelRef.target)
        }
        @Test func appendNewObjectModelTargetinChilds() async throws {
            // given
            let systemModelRef = try #require(await objectModelRef.config.parent.ref)
            
            try await #require(systemModelRef.isUpdating == true)
            try await #require(systemModelRef.objects.count == 1)
            
            try #require(objectModelRef.role == .root)
            try await #require(objectModelRef.childs.count == 0)
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await systemModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await objectModelRef.createChildObject()
                }
            }
            
            // then
            try await #require(systemModelRef.objects.count == 2)
            
            let newObject = try #require(await systemModelRef.objects.values.last?.ref?.target)
            
            try await #require(objectModelRef.childs.count == 1)
            await #expect(objectModelRef.childs.first == newObject)
        }
    }
    
    struct AppendNewState {
        let budClientRef: BudClient
        let objectModelRef: ObjectModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.objectModelRef = try await getRootObjectModel(budClientRef)
        }
        
        @Test func whenObjectModelIsDeleted() async throws {
            // given
            try await #require(objectModelRef.id.isExist == true)
            
            await objectModelRef.setCaptureHook {
                await objectModelRef.delete()
            }
            
            // when
            await objectModelRef.appendNewState()
            
            // then
            let issue = try #require(await objectModelRef.issue as? KnownIssue)
            #expect(issue.reason == "objectModelIsDeleted")
        }
        
        @Test func appendStateModel() async throws {
            // given
            try await #require(objectModelRef.states.isEmpty)
            
            await objectModelRef.startUpdating()
            try await #require(objectModelRef.isUpdating == true)
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await objectModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await objectModelRef.appendNewState()
                }
            }
            
            // then
            await #expect(objectModelRef.states.count == 1)
        }
        @Test func createStateModel() async throws {
            // given
            try await #require(objectModelRef.states.isEmpty)
            
            await objectModelRef.startUpdating()
            try await #require(objectModelRef.isUpdating == true)
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await objectModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await objectModelRef.appendNewState()
                }
            }
            
            // then
            try await #require(objectModelRef.states.count == 1)
            
            let stateModel = try #require(await objectModelRef.states.values.first)
            await #expect(stateModel.isExist == true)
        }
    }
    struct AppendNewAction {
        let budClientRef: BudClient
        let objectModelRef: ObjectModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.objectModelRef = try await getRootObjectModel(budClientRef)
        }
        
        @Test func whenObjectModelIsDeleted() async throws {
            // given
            try await #require(objectModelRef.id.isExist == true)
            
            await objectModelRef.setCaptureHook {
                await objectModelRef.delete()
            }
            
            // when
            await objectModelRef.appendNewAction()
            
            // then
            let issue = try #require(await objectModelRef.issue as? KnownIssue)
            #expect(issue.reason == "objectModelIsDeleted")
        }
        
        @Test func appendActionModel() async throws {
            // given
            try await #require(objectModelRef.actions.isEmpty)
            
            await objectModelRef.startUpdating()
            try await #require(objectModelRef.isUpdating == true)
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await objectModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await objectModelRef.appendNewAction()
                }
            }
            
            // then
            try await #require(objectModelRef.actions.count == 1)
        }
        @Test func createActionModel() async throws {
            // given
            try await #require(objectModelRef.actions.isEmpty)
            
            await objectModelRef.startUpdating()
            try await #require(objectModelRef.isUpdating == true)
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await objectModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await objectModelRef.appendNewAction()
                }
            }
            
            // then
            try await #require(objectModelRef.actions.count == 1)
            
            let actionModel = try #require(await objectModelRef.actions.values.first)
            await #expect(actionModel.isExist == true)
        }
    }
    
    struct RemoveObject {
        let budClientRef: BudClient
        let objectModelRef: ObjectModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.objectModelRef = try await getRootObjectModel(budClientRef)
        }
        
        @Test func whenObjectModelIsDeleted() async throws {
            // given
            try await #require(objectModelRef.id.isExist == true)
            
            await objectModelRef.setCaptureHook {
                await objectModelRef.delete()
            }
            
            // when
            await objectModelRef.removeObject()
            
            // then
            let issue = try #require(await objectModelRef.issue as? KnownIssue)
            #expect(issue.reason == "objectModelIsDeleted")
        }
        
        @Test func setRootNilWhenRemoveRootObject_SystemModel() async throws {
            // given
            let systemModelRef = try #require(await objectModelRef.config.parent.ref)
            
            try await #require(systemModelRef.objects.count == 1)
            try await #require(systemModelRef.root != nil)
            
            try #require(objectModelRef.role == .root)
            
            // when
            try await removeObject(objectModelRef)
            
            // then
            await #expect(systemModelRef.root == nil)
        }
        
        @Test func deleteObjectModel() async throws {
            // given
            await objectModelRef.startUpdating()
            try await #require(objectModelRef.isUpdating == true)
            
            try await #require(objectModelRef.id.isExist == true)
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await objectModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await objectModelRef.removeObject()
                }
            }
            
            // then
            await #expect(objectModelRef.id.isExist == false)
        }
        @Test func deleteActionModels() async throws {
            // given
            await objectModelRef.startUpdating()
            try await #require(objectModelRef.isUpdating == true)
            
            try await createActionModel(objectModelRef)
            try await createActionModel(objectModelRef)
            
            try await #require(objectModelRef.actions.count == 2)
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await objectModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await objectModelRef.removeObject()
                }
            }
            
            // then
            for actionModel in await objectModelRef.actions.values {
                await #expect(actionModel.isExist == false)
            }
        }
        @Test func deleteStateModels() async throws {
            // given
            await objectModelRef.startUpdating()
            try await #require(objectModelRef.isUpdating == true)
            
            try await createStateModel(objectModelRef)
            try await createStateModel(objectModelRef)
            
            try await #require(objectModelRef.states.count == 2)
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await objectModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await objectModelRef.removeObject()
                }
            }
            
            // then
            for stateModel in await objectModelRef.states.values {
                await #expect(stateModel.isExist == false)
            }
        }
        
        @Test func deleteGetterModels() async throws {
            // given
            await objectModelRef.startUpdating()
            try await #require(objectModelRef.isUpdating == true)
            
            let stateModelRef = try await createStateModel(objectModelRef)
            
            await stateModelRef.startUpdating()
            try await #require(stateModelRef.isUpdating == true)
            
            // given
            try await #require(stateModelRef.getters.count == 0)
            
            try await createGetterModel(stateModelRef)
            try await createGetterModel(stateModelRef)
            
            try await #require(stateModelRef.getters.count == 2)
            
            // when
            try await removeObject(objectModelRef)
            
            // then
            for getterModel in await stateModelRef.getters.values {
                await #expect(getterModel.isExist == false)
            }
        }
        @Test func deleteSetterModels() async throws {
            // given
            await objectModelRef.startUpdating()
            try await #require(objectModelRef.isUpdating == true)
            
            let stateModelRef = try await createStateModel(objectModelRef)
            
            await stateModelRef.startUpdating()
            try await #require(stateModelRef.isUpdating == true)
            
            // given
            try await #require(stateModelRef.setters.count == 0)
            
            try await createSetterModel(stateModelRef)
            try await createSetterModel(stateModelRef)
            
            try await #require(stateModelRef.setters.count == 2)
            
            // when
            try await removeObject(objectModelRef)
            
            // then
            for setterModel in await stateModelRef.setters.values {
                await #expect(setterModel.isExist == false)
            }
        }   
    }
}

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
            
            logger.end("테스트 준비 끝")
        }
        
        @Test func whenObjectModelIsDeleted() async throws {
            // given
            try await #require(objectModelRef.id.isExist == true)
            
            await updaterRef.setCaptureHook {
                await objectModelRef.delete()
            }
            
            // when
            await updaterRef.update()
            
            // then
            let issue = try #require(await updaterRef.issue as? KnownIssue)
            #expect(issue.reason == "objectModelIsDeleted")
        }
        
        @Test func deleteObjectModel() async throws {
            // given
            await updaterRef.appendEvent(.removed)
            
            // when
            await updaterRef.update()
            
            // then
            await #expect(objectModelRef.id.isExist == false)
        }
        @Test func removeObjectModelInSystemModel() async throws {
            // given
            let systemModelRef = await objectModelRef.config.parent.ref!
            try await #require(systemModelRef.objects.count == 1)
            
            await updaterRef.appendEvent(.removed)
            
            // when
            await updaterRef.update()
            
            // then
            let target = objectModelRef.target
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
                role: .root,
                parent: nil,
                childs: [])
            
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
                role: .root,
                parent: nil,
                childs: [])
            
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
            
            await systemModelRef.createRootObject()
        }
    }
    
    let rootObjectModelRef = try #require(await systemModelRef.root?.ref)
    return rootObjectModelRef
}

@discardableResult
private func createStateModel(_ objectModelRef: ObjectModel) async throws -> StateModel {
    try await #require(objectModelRef.isUpdating == true)
    
    let oldCount = await objectModelRef.states.count
    
    await withCheckedContinuation { continuation in
        Task {
            await objectModelRef.setCallback {
                continuation.resume()
            }
            
            await objectModelRef.appendNewState()
        }
    }
    
    try await #require(objectModelRef.states.count == oldCount + 1)
    
    let stateModel = try #require(await objectModelRef.states.values.last)
    return try #require(await stateModel.ref)
}

@discardableResult
private func createGetterModel(_ stateModelRef: StateModel) async throws -> GetterModel {
    await stateModelRef.startUpdating()
    try await #require(stateModelRef.isUpdating == true)
    
    let oldCount = await stateModelRef.getters.count
    
    await withCheckedContinuation { continuation in
        Task {
            await stateModelRef.setCallback {
                continuation.resume()
            }
            
            await stateModelRef.appendNewGetter()
        }
    }
    
    try await #require(stateModelRef.getters.count == oldCount + 1)
    
    let getterModel = try #require(await stateModelRef.getters.values.last)
    return try #require(await getterModel.ref)
}

@discardableResult
private func createSetterModel(_ stateModelRef: StateModel) async throws -> SetterModel {
    await stateModelRef.startUpdating()
    try await #require(stateModelRef.isUpdating == true)
    
    let oldCount = await stateModelRef.setters.count
    
    await withCheckedContinuation { continuation in
        Task {
            await stateModelRef.setCallback {
                continuation.resume()
            }
            
            await stateModelRef.appendNewSetter()
        }
    }
    
    try await #require(stateModelRef.setters.count == oldCount + 1)
    
    let setterModel = try #require(await stateModelRef.setters.values.last)
    return try #require(await setterModel.ref)
}


private func createActionModel(_ objectModelRef: ObjectModel) async throws {
    try await #require(objectModelRef.isUpdating == true)
    
    let oldCount = await objectModelRef.actions.count
    
    await withCheckedContinuation { continuation in
        Task {
            await objectModelRef.setCallback {
                continuation.resume()
            }
            
            await objectModelRef.appendNewAction()
        }
    }
    
    try await #require(objectModelRef.actions.count == oldCount + 1)
}


// MARK: Helpehrs - action
private func removeObject(_ objectModelRef: ObjectModel) async throws {
    await objectModelRef.startUpdating()
    try await #require(objectModelRef.isUpdating == true)
    
    await withCheckedContinuation { continuation in
        Task {
            await objectModelRef.setCallback {
                continuation.resume()
            }
            
            await objectModelRef.removeObject()
        }
    }
}


