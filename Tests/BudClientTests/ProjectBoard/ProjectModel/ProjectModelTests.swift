//
//  ProjectModelTests.swift
//  BudClient
//
//  Created by 김민우 on 7/1/25.
//
import Foundation
import Testing
import Values
@testable import BudClient
@testable import BudServer


// MARK: Tests
@Suite("ProjectModel", .timeLimit(.minutes(1)))
struct ProjectModelTests {
    struct StartUpdating {
        let budClientRef: BudClient
        let projectModelRef: ProjectModel
        let projectSourceRef: ProjectSourceMock
        init() async throws {
            self.budClientRef = await BudClient()
            self.projectModelRef = try await getProjectModel(budClientRef)
            self.projectSourceRef = await projectModelRef.source.ref as! ProjectSourceMock
        }
        
        @Test func whenProjectModelIsDeleted() async throws {
            // given
            try await #require(projectModelRef.id.isExist == true)
            
            await projectModelRef.setCaptureHook {
                await projectModelRef.delete()
            }
            
            // when
            await projectModelRef.startUpdating()
            
            // then
            let issue = try #require(await projectModelRef.issue as? KnownIssue)
            #expect(issue.reason == "projectModelIsDeleted")
            
        }
        
        @Test func setIsUpdatingTrue() async throws {
            // given
            try await #require(projectModelRef.isUpdating == false)
            
            // when
            await projectModelRef.startUpdating()
            
            // then
            await #expect(projectModelRef.isUpdating == true)
        }
        @Test func whenAlreadyUpdating() async throws {
            // given
            await projectModelRef.startUpdating()
            
            try await #require(projectModelRef.issue == nil)
            
            // when
            await projectModelRef.startUpdating()
            
            // then
            let issue = try #require(await projectModelRef.issue as? KnownIssue)
            #expect(issue.reason == "alreadyUpdating")
        }
        
        @Test func receiveInitialEvents() async throws {
            // given
            try await #require(projectModelRef.systems.isEmpty)
            try await #require(projectSourceRef.systems.isEmpty)
            
            await projectModelRef.createFirstSystem()
            
            try await #require(projectModelRef.systems.isEmpty)
            try await #require(projectSourceRef.systems.count == 1)
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await projectModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await projectModelRef.startUpdating()
                }
            }
            
            // then
            await #expect(projectModelRef.systems.count == 1)
        }
    }
    
    struct PushName {
        let budClientRef: BudClient
        let projectModelRef: ProjectModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.projectModelRef = try await getProjectModel(budClientRef)
        }
        
        @Test func whenProjectModelIsDeleted() async throws {
            // given
            try await #require(projectModelRef.id.isExist == true)
            
            await projectModelRef.setCaptureHook {
                await projectModelRef.delete()
            }
            
            // when
            await projectModelRef.pushName()
            
            // then
            let issue = try #require(await projectModelRef.issue)
            #expect(issue.reason == "projectModelIsDeleted")
        }
        
        @Test func whenNameInputIsEmpty() async throws {
            // given
            await MainActor.run {
                projectModelRef.nameInput = ""
            }
            
            // when
            await projectModelRef.pushName()
            
            // then
            let issue = try #require(await projectModelRef.issue as? KnownIssue)
            #expect(issue.reason == "nameCannotBeEmpty")
        }
        @Test func whenNameInputIsSameWithName() async throws {
            // given
            await MainActor.run {
                projectModelRef.nameInput = "TEST"
                projectModelRef.name = "TEST"
            }
            
            // when
            await projectModelRef.pushName()
            
            // then
            let issue = try #require(await projectModelRef.issue as? KnownIssue)
            #expect(issue.reason == "newNameIsSameAsCurrent")
        }
        
        @Test func updateNameByHandler() async throws {
            // given
            let testName = "TEST_PROJECT_NAME"
            
            await MainActor.run {
                projectModelRef.nameInput = testName
            }
            
            // then
            await projectModelRef.startUpdating()
            await withCheckedContinuation { continuation in
                Task {
                    await projectModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await projectModelRef.pushName()
                }
            }
            
            
            // then
            await #expect(projectModelRef.name == testName)
        }
    }
    
    struct CreateFirstSystem {
        let budClientRef: BudClient
        let projectModelRef: ProjectModel
        let projectSourceRef: ProjectSourceMock
        init() async throws {
            self.budClientRef = await BudClient()
            self.projectModelRef = try await getProjectModel(budClientRef)
            self.projectSourceRef = await projectModelRef.source.ref as! ProjectSourceMock
        }
        
        @Test func whenProjectModelIsDeleted() async throws {
            // given
            try await #require(projectModelRef.id.isExist == true)
            
            await projectModelRef.setCaptureHook {
                await projectModelRef.delete()
            }
            // when
            await projectModelRef.createFirstSystem()
            
            // then
            let issue = try #require(await projectModelRef.issue as? KnownIssue)
            #expect(issue.reason == "projectModelIsDeleted")
        }
        
        @Test func createSystemModel() async throws {
            // given
            try await #require(projectModelRef.systems.isEmpty == true)
            try await #require(projectSourceRef.systems.isEmpty)
            
            await projectModelRef.startUpdating()
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await projectModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await projectModelRef.createFirstSystem()
                }
            }
            
            // then
            try await #require(projectModelRef.systems.count == 1)
            
            let systemModel = try #require(await projectModelRef.systems.values.first)
            await #expect(systemModel.isExist == true)
        }
        @Test func createSystemSource() async throws {
            // given
            let projectSourceRef = try #require(await projectModelRef.source.ref as? ProjectSourceMock)
            
            try await #require(projectSourceRef.systems.isEmpty == true)
            
            // when
            await projectModelRef.createFirstSystem()
            
            // then
            await #expect(projectSourceRef.systems.count == 1)
        }
        
        @Test func whenFirstSystemAlreadyExist() async throws {
            // given
            try await #require(projectModelRef.systems.isEmpty)
            
            await projectModelRef.startUpdating()
            await withCheckedContinuation { continuation in
                Task {
                    await projectModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await projectModelRef.createFirstSystem()
                }
            }
            
            try await #require(projectModelRef.systems.count == 1)
            try await #require(projectModelRef.issue == nil)
            
            // when
            await projectModelRef.createFirstSystem()
            
            // then
            try await #require(projectModelRef.systems.count == 1)
            
            let issue = try #require(await projectModelRef.issue as? KnownIssue)
            #expect(issue.reason == "firstSystemAlreadyExist")
        }
    }
    
    struct CreateValue {
        let budClientRef: BudClient
        let projectModelRef: ProjectModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.projectModelRef = try await getProjectModel(budClientRef)
        }
        
        @Test func whenProjectModelIsDeleted() async throws {
            // given
            try await #require(projectModelRef.id.isExist == true)
            
            await projectModelRef.setCaptureHook {
                await projectModelRef.delete()
            }
            
            // when
            await projectModelRef.createValue()
            
            // then
            let issue = try #require(await projectModelRef.issue as? KnownIssue)
            #expect(issue.reason == "projectModelIsDeleted")
        }
        
        @Test func createValueModel() async throws {
            // given
            try await #require(projectModelRef.values.isEmpty == true)
            
            await projectModelRef.startUpdating()
            try await #require(projectModelRef.isUpdating == true)
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await projectModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await projectModelRef.createValue()
                }
            }
            
            // then
            try await #require(projectModelRef.values.count == 1)
            
            let valueModel = try #require(await projectModelRef.values.values.first)
            await #expect(valueModel.isExist == true)
        }
    }
    

    struct RemoveProject {
        let budClientRef: BudClient
        let projectModelRef: ProjectModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.projectModelRef = try await getProjectModel(budClientRef)
        }
        
        @Test func whenProjectEditorIsDeleted() async throws {
            // given
            try await #require(projectModelRef.id.isExist == true)
            
            await projectModelRef.setCaptureHook {
                await projectModelRef.delete()
            }
            
            // when
            await projectModelRef.removeProject()
            
            // then
            let issue = try #require(await projectModelRef.issue)
            #expect(issue.reason == "projectModelIsDeleted")
        }
        
        @Test func removeProjectSource() async throws {
            // given
            let projectSource = projectModelRef.source
            
            await #expect(projectSource.isExist == true)
             
            // when
            await projectModelRef.removeProject()
            
            // then
            await #expect(projectSource.isExist == false)
        }
        @Test func removeProjectModelInProjectBoard() async throws {
            // given
            let projectBoardRef = try #require(await projectModelRef.config.parent.ref)
            try await #require(projectBoardRef.projects.values.contains(projectModelRef.id))
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await projectModelRef.startUpdating()
                    await projectModelRef.setCallback { continuation.resume() }
                    await #expect(projectModelRef.issue == nil)
                    
                    await projectModelRef.removeProject()
                }
            }
            
            // then
            await #expect(projectBoardRef.projects.values.contains(projectModelRef.id) == false)
            
        }
        
        @Test func deleteProjectModel() async throws {
            // given
            await projectModelRef.startUpdating()
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await projectModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await #expect(projectModelRef.issue == nil)
                    
                    await projectModelRef.removeProject()
                }
            }
            
            // then
            await #expect(projectModelRef.id.isExist == false)
        }
        
        @Test func deleteValueModels() async throws {
            // given
            try await #require(projectModelRef.values.count == 0)
            
            try await createValueModel(projectModelRef)
            try await createValueModel(projectModelRef)
            try await createValueModel(projectModelRef)
            
            try await #require(projectModelRef.values.count == 3)
            
            // when
            try await removeProject(projectModelRef)
            
            // then
            for valueModel in await projectModelRef.values.values {
                await #expect(valueModel.isExist == false)
            }
        }
        
        @Test func deleteSystemModels() async throws {
            // given
            await projectModelRef.startUpdating()
            try await #require(projectModelRef.systems.isEmpty)
            
            await withCheckedContinuation { continuation in
                Task {
                    await projectModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await projectModelRef.createFirstSystem()
                }
            }
            
            try await #require(projectModelRef.systems.count == 1)
            
            let systemModel = try #require(await projectModelRef.systems.values.first)
            
            // when
            try await removeProject(projectModelRef)
            
            // then
            await #expect(systemModel.isExist == false)
        }
        @Test func deleteRootObjectModel() async throws {
            // give
            let systemModelRef = try await createSystem(projectModelRef)
            let rootObjectModelRef = try await createRootObjectModel(systemModelRef)
            
            try await #require(rootObjectModelRef.id.isExist == true)
            
            // when
            try await removeProject(projectModelRef)
            
            // then
            await #expect(rootObjectModelRef.id.isExist == false)
        }
        @Test func deleteStateModels() async throws {
            // given
            let systemModelRef = try await createSystem(projectModelRef)
            let rootObjectModelRef = try await createRootObjectModel(systemModelRef)
            
            try await #require(rootObjectModelRef.states.count == 0)
            
            try await createStateModel(rootObjectModelRef)
            try await createStateModel(rootObjectModelRef)
            
            try await #require(rootObjectModelRef.states.count == 2)
            
            // when
            try await removeProject(projectModelRef)
        }
        @Test func deleteGetterModels() async throws {
            // given
            let systemModelRef = try await createSystem(projectModelRef)
            let rootObjectModelRef = try await createRootObjectModel(systemModelRef)
            let stateModelRef = try await createStateModel(rootObjectModelRef)
            
            try await #require(stateModelRef.getters.count == 0)
            
            try await createGetterModel(stateModelRef)
            try await createGetterModel(stateModelRef)
            
            try await #require(stateModelRef.getters.count == 2)
            
            // when
            try await removeProject(projectModelRef)
            
            // then
            for getterModel in await stateModelRef.getters.values {
                await #expect(getterModel.isExist == false)
            }
        }
        @Test func deleteSetterModels() async throws {
            // given
            let systemModelRef = try await createSystem(projectModelRef)
            let rootObjectModelRef = try await createRootObjectModel(systemModelRef)
            let stateModelRef = try await createStateModel(rootObjectModelRef)
            
            try await #require(stateModelRef.setters.count == 0)
            
            try await createSetterModel(stateModelRef)
            try await createSetterModel(stateModelRef)
            
            try await #require(stateModelRef.setters.count == 2)
            
            // when
            try await removeProject(projectModelRef)
            
            // then
            for setterModel in await stateModelRef.setters.values {
                await #expect(setterModel.isExist == false)
            }
        }
        @Test func deleteActionModels() async throws {
            // given
            let systemModelRef = try await createSystem(projectModelRef)
            let rootObjectModelRef = try await createRootObjectModel(systemModelRef)
            
            try await #require(rootObjectModelRef.actions.count == 0)
            
            try await createActionModel(rootObjectModelRef)
            try await createActionModel(rootObjectModelRef)
            
            try await #require(rootObjectModelRef.actions.count == 2)
            
            // when
            try await removeProject(projectModelRef)
            
            // then
            for actionModel in await rootObjectModelRef.actions.values {
                await #expect(actionModel.isExist == false)
            }
        }
        
        @Test(.disabled("구현 예정")) func deleteFlowModels() async throws {}
        
        @Test(.disabled("구현 예정")) func deleteWorkflowModels() async throws {}
    }
}


// MARK: Tests
@Suite("ProjectModelUpdater", .timeLimit(.minutes(1)))
struct ProjectModelUpdaterTests {
    struct Update {
        let budClientRef: BudClient
        let projectModelRef: ProjectModel
        let updaterRef: ProjectModel.Updater
        let sourceRef: ProjectSourceMock
        init() async throws {
            self.budClientRef = await BudClient()
            self.projectModelRef = try await getProjectModel(budClientRef)
            self.updaterRef = projectModelRef.updaterRef
            self.sourceRef = try #require(await projectModelRef.source.ref as? ProjectSourceMock)
        }
        
        @Test func whenProjectModelIsDeleted() async throws {
            // given
            try await #require(projectModelRef.id.isExist == true)
            
            await updaterRef.setCaptureHook {
                await projectModelRef.delete()
            }
            
            await updaterRef.appendEvent(.removed)
            try await #require(updaterRef.queue.isEmpty == false)
            
            // when
            await updaterRef.update()
            
            // then
            let issue = try #require(await updaterRef.issue as? KnownIssue)
            #expect(issue.reason == "projectModelIsDeleted")
        }
        @Test func whenEventQueueIsEmpty() async throws {
            // given
            try await #require(updaterRef.queue.isEmpty == true)
            try await #require(updaterRef.issue == nil)
            
            // when
            await updaterRef.update()
            
            // then
            let issue = try #require(await updaterRef.issue as? KnownIssue)
            #expect(issue.reason == "eventQueueIsEmpty")
        }
        
        // ProjectSourceEvent.modified
        @Test func modifyProjectModelName() async throws {
            // given
            let newName = "NEW_NAME"
            await sourceRef.setName(newName)
            
            let newDiff = await ProjectSourceDiff(sourceRef)
            
            // when
            await updaterRef.appendEvent(.modified(newDiff))
            await updaterRef.update()
            
            try await #require(updaterRef.isIssueOccurred == false)
            
            // then
            await #expect(projectModelRef.name == newName)
        }
        
        // ProjectSourceEvent.removed
        @Test func deleteProjectModel() async throws {
            // given
            await updaterRef.appendEvent(.removed)
            
            // when
            await updaterRef.update()
            
            // then
            try await #require(updaterRef.isIssueOccurred == false)
            await #expect(projectModelRef.id.isExist == false)
        }
        @Test func whenProjectModelAlreadyRemoved() async throws {
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
        @Test func deleteSystemModels() async throws {
            // given
            try await #require(projectModelRef.systems.count == 0)
            
            await projectModelRef.startUpdating()
            try await createSystem(projectModelRef)
            
            try await #require(projectModelRef.systems.count == 1)
            
            // when
            await updaterRef.appendEvent(.removed)
            await updaterRef.update()
            
            // then
            for systemModel in await projectModelRef.systems.values {
                await #expect(systemModel.isExist == false)
            }
        }
        @Test func deleteObjectModels() async throws {
            
        }
        
        
        // ProjectSourceEvent.systemAdded
        @Test func createSystemModel() async throws {
            // given
            try await #require(projectModelRef.systems.count == 0)
            
            let diff = SystemSourceDiff(
                id: SystemSourceMock.ID(),
                target: .init(),
                createdAt: .now,
                updatedAt: .now,
                order: 0,
                name: "TEST_NAME",
                location: .init(x: 999, y: 999))
            
            await updaterRef.appendEvent(.systemAdded(diff))
            
            // when
            await updaterRef.update()
            
            // then
            try await #require(projectModelRef.systems.count == 1)
            try await #require(updaterRef.queue.isEmpty)
            
            await #expect(projectModelRef.systems.values.first?.isExist == true)
        }
        @Test func whenSystemModelAlreadyAdded() async throws {
            // given
            let newSystemSourceMockRef = await SystemSourceMock(
                name: "",
                location: .origin,
                parent: .init()
            )
            let diff = await SystemSourceDiff(newSystemSourceMockRef)
            
            await updaterRef.appendEvent(.systemAdded(diff))
            await updaterRef.update()
            
            // when
            await updaterRef.appendEvent(.systemAdded(diff))
            await updaterRef.update()
            
            // then
            try await #require(updaterRef.queue.isEmpty)
            
            let issue = try #require(await updaterRef.issue as? KnownIssue)
            #expect(issue.reason == "alreadyAdded")
        }
        
        // ProjectSourceEvent.valueAdded
        @Test func createValueModel() async throws {
            // given
            try await #require(projectModelRef.values.count == 0)
            try await #require(updaterRef.queue.isEmpty == true)
            
            let valueSourceRef = await ValueSourceMock(owner: sourceRef.id)
            let newDiff = await ValueSourceDiff(valueSourceRef)
                        
            await updaterRef.appendEvent(.valueAdded(newDiff))
            try await #require(updaterRef.queue.count == 1)
            
            // when
            await updaterRef.update()
            
            // then
            try await #require(projectModelRef.values.count == 1)
            
            let valueModel = try #require(await projectModelRef.values.values.first)
            await #expect(valueModel.isExist == true)
        }
        @Test func whenValueModeAlreadyAdded() async throws {
            // given
            let valueSourceRef = await ValueSourceMock(owner: sourceRef.id)
            let newDiff = await ValueSourceDiff(valueSourceRef)
            await updaterRef.appendEvent(.valueAdded(newDiff))
            
            await updaterRef.update()
            try await #require(updaterRef.issue == nil)
            
            // when
            await updaterRef.appendEvent(.valueAdded(newDiff))
            await updaterRef.update()
            
            // then
            let issue = try #require(await updaterRef.issue as? KnownIssue)
            #expect(issue.reason == "alreadyAdded")
        }
    }
}


// MARK: Helphers
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
    
    // ProjectEditor
    await #expect(projectBoardRef.projects.count == 1)
    return try #require(await projectBoardRef.projects.values.first?.ref)
}

@discardableResult
private func createSystem(_ projectModelRef: ProjectModel) async throws -> SystemModel {
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
    
    return try #require(await projectModelRef.systems.values.first?.ref)
}

@discardableResult
private func createRootObjectModel(_ systemModelRef: SystemModel) async throws -> ObjectModel {
    try await #require(systemModelRef.root == nil)
    
    await withCheckedContinuation { continuation in
        Task {
            await systemModelRef.setCallback {
                continuation.resume()
            }
            
            await systemModelRef.startUpdating()
            
            await systemModelRef.createRootObject()
        }
    }
    
    try await #require(systemModelRef.objects.count == 1)
    return try #require(await systemModelRef.root?.ref)
}

@discardableResult
private func createStateModel(_ objectModelRef: ObjectModel) async throws -> StateModel {
    
    await objectModelRef.startUpdating()
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
    
    let newCount = await objectModelRef.states.count
    try #require(newCount == oldCount + 1)
    
    let newStateModel = try #require(await objectModelRef.states.values.last)
    
    return try #require(await newStateModel.ref)
}

@discardableResult
private func createActionModel(_ objectModelRef: ObjectModel) async throws -> ActionModel {
    await objectModelRef.startUpdating()
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
    
    let newCount = await objectModelRef.actions.count
    try #require(newCount == oldCount + 1)
    
    let newActionModel = try #require(await objectModelRef.actions.values.last)
    
    return try #require(await newActionModel.ref)
}

private func createGetterModel(_ stateModelRef: StateModel) async throws {
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
    
    let newCount = await stateModelRef.getters.count
    
    try #require(newCount == oldCount + 1)
}

private func createSetterModel(_ stateModelRef: StateModel) async throws {
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
    
    let newCount = await stateModelRef.setters.count
    
    try #require(newCount == oldCount + 1)
}

private func createValueModel(_ projectModelRef: ProjectModel) async throws {
    await projectModelRef.startUpdating()
    try await #require(projectModelRef.isUpdating == true)
    
    await withCheckedContinuation { continuation in
        Task {
            await projectModelRef.setCallback {
                continuation.resume()
            }
            
            await projectModelRef.createValue()
        }
    }
}

// MARK: Helpehrs - action
private func removeProject(_ projectModelRef: ProjectModel) async throws {
    await projectModelRef.startUpdating()
    try await #require(projectModelRef.isUpdating == true)
    
    await withCheckedContinuation { continuation in
        Task {
            await projectModelRef.setCallback {
                continuation.resume()
            }
            
            await projectModelRef.removeProject()
        }
    }
}
