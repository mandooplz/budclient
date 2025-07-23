//
//  SystemModelTests.swift
//  BudClient
//
//  Created by 김민우 on 7/8/25.
//
import Foundation
import Testing
import Values
@testable import BudClient
@testable import BudServer

private let logger = BudLogger("SystemModelTests")


// MARK: Tests
@Suite("SystemModel", .timeLimit(.minutes(1)))
struct SystemModelTests {
    struct StartUpdating {
        let budClientRef: BudClient
        let systemModelRef: SystemModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.systemModelRef = try await getSystemModel(budClientRef)
        }
        
        @Test func whenSystemModelIsDeleted() async throws {
            // given
            try await #require(systemModelRef.id.isExist == true)
            
            await systemModelRef.setCaptureHook {
                await systemModelRef.delete()
            }
            
            // when
            await systemModelRef.startUpdating()
            
            // then
            let issue = try #require(await systemModelRef.issue as? KnownIssue)
            #expect(issue.reason == "systemModelIsDeleted")
        }
        
        @Test func setIsUpdatingTrue() async throws {
            // given
            try await #require(systemModelRef.isUpdating == false)
            
            // when
            await systemModelRef.startUpdating()
            
            // then
            await #expect(systemModelRef.isUpdating == true)
        }
        @Test func whenAlreadyUpdating() async throws {
            // given
            await systemModelRef.startUpdating()
            
            try await #require(systemModelRef.issue == nil)
            
            // when
            await systemModelRef.startUpdating()
            
            // then
            let issue = try #require(await systemModelRef.issue as? KnownIssue)
            #expect(issue.reason == "alreadyUpdating")
        }
    }
    
    struct PushName {
        let budClientRef: BudClient
        let systemModelRef: SystemModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.systemModelRef = try await getSystemModel(budClientRef)
        }
        
        @Test func whenSystemModelIsDeleted() async throws {
            // given
            try await #require(systemModelRef.id.isExist == true)
            
            await systemModelRef.setCaptureHook {
                await systemModelRef.delete()
            }
            
            // when
            await systemModelRef.pushName()
            
            // then
            let issue = try #require(await systemModelRef.issue as? KnownIssue)
            #expect(issue.reason == "systemModelIsDeleted")
        }
        @Test func whenNameInputIsEmpty() async throws {
            // given
            await MainActor.run {
                systemModelRef.nameInput = ""
            }
            
            // when
            await systemModelRef.pushName()
            
            // then
            let issue = try #require(await systemModelRef.issue as? KnownIssue)
            #expect(issue.reason == "nameCannotBeEmpty")
        }
        @Test func whenNameInputIsSameWithName() async throws {
            // given
            let testName = "TEST_NAME_22"
            await MainActor.run {
                systemModelRef.name = testName
                systemModelRef.nameInput = testName
            }
            
            // when
            await systemModelRef.pushName()
            
            // then
            let issue = try #require(await systemModelRef.issue as? KnownIssue)
            #expect(issue.reason == "newNameIsSameAsCurrent")
        }
        
        @Test func updateNameByUpdater() async throws {
            // given
            let testName = "TEST_NAME"
            await MainActor.run {
                systemModelRef.nameInput = testName
            }
            
            try await #require(systemModelRef.name != testName)
            try await #require(systemModelRef.id.isExist == true)
            
            // when
            await systemModelRef.startUpdating()
            await withCheckedContinuation { continuation in
                Task {
                    await systemModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await systemModelRef.pushName()
                }
            }
            
            
            // then
            await #expect(systemModelRef.name == testName)
        }
    }
    
    struct AddSystemRight {
        let budClientRef: BudClient
        let systemModelRef: SystemModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.systemModelRef = try await getSystemModel(budClientRef)
        }
        
        @Test func whenSystemModelIsDeleted() async throws {
            // given
            try await #require(systemModelRef.id.isExist == true)
            
            await systemModelRef.setCaptureHook {
                await systemModelRef.delete()
            }
            
            // when
            await systemModelRef.addSystemRight()
            
            // then
            let issue = try #require(await systemModelRef.issue as? KnownIssue)
            #expect(issue.reason == "systemModelIsDeleted")
        }
        
        @Test func addRightSystemModel_ProjectModel() async throws {
            // given
            let projectModelRef = try #require(await systemModelRef.config.parent.ref)
            
            let rightLocation = await systemModelRef.location.getRight()
            try await #require( projectModelRef.systemLocations.contains(rightLocation) == false)
            
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await projectModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await systemModelRef.addSystemRight()
                }
            }
            
            // then
            try await #require( projectModelRef.systemLocations.contains(rightLocation) == true)
        }
        @Test func whenRightSystemModelIsAlreadyExist() async throws {
            // given
            let rightLocation = await systemModelRef.location.getRight()
            let projectSourceRef = try #require(await systemModelRef
                .config.parent.ref?
                .source.ref as? ProjectSourceMock)
            
            try await #require(projectSourceRef.systems.count == 1)
            
            // when
            await systemModelRef.addSystemRight()
            await systemModelRef.addSystemRight()
            await systemModelRef.addSystemRight()
            await systemModelRef.addSystemRight()
            
            // then
            try await #require(projectSourceRef.isLocationExist(rightLocation) == true)
            
            await #expect(projectSourceRef.systems.count == 2)
        }
    }
    
    struct AddSystemLeft {
        let budClientRef: BudClient
        let systemModelRef: SystemModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.systemModelRef = try await getSystemModel(budClientRef)
        }
        
        @Test func whenSystemModelIsDeleted() async throws {
            // given
            try await #require(systemModelRef.id.isExist == true)
            
            await systemModelRef.setCaptureHook {
                await systemModelRef.delete()
            }
            
            // when
            await systemModelRef.addSystemLeft()
            
            // then
            let issue = try #require(await systemModelRef.issue as? KnownIssue)
            #expect(issue.reason == "systemModelIsDeleted")
        }
    
        @Test func addLeftSystemModel_ProjectModel() async throws {
            // given
            let projectModelRef = try #require(await systemModelRef.config.parent.ref)
            
            let leftLocation = await systemModelRef.location.getLeft()
            try await #require(projectModelRef.systemLocations.contains(leftLocation) ==  false)
            
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await projectModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await systemModelRef.addSystemLeft()
                }
            }
            
            // then
            try await #require(projectModelRef.systemLocations.contains(leftLocation))
        }
        @Test func whenLeftSystemModelIsAlreadyExist() async throws {
            // given
            let leftLocation = await systemModelRef.location.getLeft()
            let projectSourceRef = try #require(await systemModelRef
                .config.parent.ref?
                .source.ref as? ProjectSourceMock)
            
            try await #require(projectSourceRef.systems.count == 1)
            
            // when
            await systemModelRef.addSystemLeft()
            await systemModelRef.addSystemLeft()
            await systemModelRef.addSystemLeft()
            await systemModelRef.addSystemLeft()
            
            // then
            try await #require(projectSourceRef.isLocationExist(leftLocation) == true)
            
            await #expect(projectSourceRef.systems.count == 2)
        }
    }
    
    struct AddSystemTop {
        let budClientRef: BudClient
        let systemModelRef: SystemModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.systemModelRef = try await getSystemModel(budClientRef)
        }
        
        @Test func whenSystemModelIsDeleted() async throws {
            // given
            try await #require(systemModelRef.id.isExist == true)
            
            await systemModelRef.setCaptureHook {
                await systemModelRef.delete()
            }
            
            // when
            await systemModelRef.addSystemTop()
            
            // then
            let issue = try #require(await systemModelRef.issue as? KnownIssue)
            #expect(issue.reason == "systemModelIsDeleted")
        }
        
        @Test func addTopSystemModel_ProjectModel() async throws {
            // given
            let projectModelRef = try #require(await systemModelRef.config.parent.ref)
            
            let topLocation = await systemModelRef.location.getTop()
            try await #require(projectModelRef.systemLocations.contains( topLocation) == false)

            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await projectModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await systemModelRef.addSystemTop()
                }
            }
            
            // then
            try await #require( projectModelRef.systemLocations.contains(topLocation) == true)
        }
        @Test func whenTopSystemModelIsAlreadyExist() async throws {
            // given
            let topLocation = await systemModelRef.location.getTop()
            let projectSourceRef = try #require(await systemModelRef
                .config.parent.ref?
                .source.ref as? ProjectSourceMock)
            
            try await #require(projectSourceRef.systems.count == 1)
            
            // when
            await systemModelRef.addSystemTop()
            await systemModelRef.addSystemTop()
            await systemModelRef.addSystemTop()
            await systemModelRef.addSystemTop()
            
            // then
            try await #require(projectSourceRef.isLocationExist(topLocation) == true)
            
            await #expect(projectSourceRef.systems.count == 2)
        }
    }
    
    struct AddSystemBottom {
        let budClientRef: BudClient
        let systemModelRef: SystemModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.systemModelRef = try await getSystemModel(budClientRef)
        }
        
        @Test func whenSystemModelIsDeleted() async throws {
            // given
            try await #require(systemModelRef.id.isExist == true)
            
            await systemModelRef.setCaptureHook {
                await systemModelRef.delete()
            }
            
            // when
            await systemModelRef.addSystemBottom()
            
            // then
            let issue = try #require(await systemModelRef.issue as? KnownIssue)
            #expect(issue.reason == "systemModelIsDeleted")
        }
        
        @Test func addBottomSystemModel_ProjectModel() async throws {
            // given
            let projectModelRef = try #require(await systemModelRef.config.parent.ref)
            
            let bottomLocation = await systemModelRef.location.getBotttom()
            try await #require(projectModelRef.systemLocations.contains(bottomLocation) == false)
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await projectModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await systemModelRef.addSystemBottom()
                }
            }
            
            // then
            try #require(await projectModelRef.systemLocations.contains(bottomLocation) == true)
        }
        @Test func whenRightSystemModelIsAlreadyExist() async throws {
            // given
            let bottomLocation = await systemModelRef.location.getBotttom()
            let projectSourceRef = try #require(await systemModelRef
                .config.parent.ref?
                .source.ref as? ProjectSourceMock)
            
            try await #require(projectSourceRef.systems.count == 1)
            
            // when
            await systemModelRef.addSystemBottom()
            await systemModelRef.addSystemBottom()
            await systemModelRef.addSystemBottom()
            await systemModelRef.addSystemBottom()
            
            // then
            try await #require(projectSourceRef.isLocationExist(bottomLocation) == true)
            
            await #expect(projectSourceRef.systems.count == 2)
        }
    }
    
    struct CreateRootObject {
        let budClientRef: BudClient
        let systemModelRef: SystemModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.systemModelRef = try await getSystemModel(budClientRef)
        }
        
        @Test func whenSystemModelIsDeleted() async throws {
            // given
            try await #require(systemModelRef.id.isExist == true)
            
            await systemModelRef.setCaptureHook {
                await systemModelRef.delete()
            }
            
            // when
            await systemModelRef.createRootObject()
            
            // then
            let issue = try #require(await systemModelRef.issue as? KnownIssue)
            #expect(issue.reason == "systemModelIsDeleted")
        }
        
        @Test func setRoot() async throws {
            // given
            try await #require(systemModelRef.root == nil)
            
            await systemModelRef.startUpdating()
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await systemModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await systemModelRef.createRootObject()
                }
            }
            
            // then
            try await #require(systemModelRef.issue == nil)
            
            await #expect(systemModelRef.root != nil)
        }
        @Test func createObjectModel() async throws {
            // given
            try await #require(systemModelRef.root == nil)
            
            await systemModelRef.startUpdating()
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await systemModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await systemModelRef.createRootObject()
                }
            }
            
            // then
            try await #require(systemModelRef.issue == nil)
            
            let rootObjectModel = try #require(await systemModelRef.root)
            await #expect(rootObjectModel.isExist == true)
        }
        @Test func appendObjectModelInObjects() async throws {
            // given
            try await #require(systemModelRef.objects.isEmpty)
            
            await systemModelRef.startUpdating()
            
            // when
        }
        
        @Test func whenRootObjectModelAlreadyExist() async throws {
            // given
            try await #require(systemModelRef.root == nil)
            
            await systemModelRef.startUpdating()
            await withCheckedContinuation { continuation in
                Task {
                    await systemModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await systemModelRef.createRootObject()
                }
            }
            
            try await #require(systemModelRef.root != nil)
            
            // when
            await systemModelRef.createRootObject()
            
            // then
            let issue = try #require(await systemModelRef.issue as? KnownIssue)
            #expect(issue.reason == "rootObjectModelAlreadyExist")
        }
    }
    
    struct RemoveSystem {
        let budClientRef: BudClient
        let systemModelRef: SystemModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.systemModelRef = try await getSystemModel(budClientRef)
            
            logger.end("테스트 준비 끝")
        }
        
        @Test func whenSystemModelIsDeleted() async throws {
            // given
            try await #require(systemModelRef.id.isExist == true)
            
            await systemModelRef.setCaptureHook {
                await systemModelRef.delete()
            }
            
            // when
            await systemModelRef.removeSystem()
            
            // then
            let issue = try #require(await systemModelRef.issue as? KnownIssue)
            #expect(issue.reason == "systemModelIsDeleted")
        }
        
        @Test func deleteSystemModel() async throws {
             // given
            try await #require(systemModelRef.id.isExist == true)
            
            await systemModelRef.startUpdating()
            
            // when
            try await removeSystem(systemModelRef)
            
            // then
            await #expect(systemModelRef.id.isExist == false)
        }
        @Test func deleteObjectModels() async throws {
            // given
            try await #require(systemModelRef.objects.isEmpty)
            try await #require(systemModelRef.root == nil)
            
            try await createRootObject(systemModelRef)
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await systemModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await systemModelRef.removeSystem()
                }
            }
            
            // then
            for objectModel in await systemModelRef.objects.values {
                await #expect(objectModel.isExist == false)
            }
        }
        @Test func deleteStateModels() async throws {
            // given
            let rootObjectModelRef = try await createRootObject(systemModelRef)
            
            try await #require(rootObjectModelRef.states.count == 0)
            
            try await createStateModel(rootObjectModelRef)
            try await createStateModel(rootObjectModelRef)
            
            try await #require(rootObjectModelRef.states.count == 2)
            
            // when
            try await removeSystem(systemModelRef)
            
            // then
            for stateModel in await rootObjectModelRef.states.values {
                await #expect(stateModel.isExist == false)
            }
        }
        @Test func deleteGetterModels() async throws {
            // given
            let rootObjectModelRef = try await createRootObject(systemModelRef)
            let stateModelRef = try await createStateModel(rootObjectModelRef)
            
            try await #require(stateModelRef.getters.count == 0)
            
            try await createGetterModel(stateModelRef)
            try await createGetterModel(stateModelRef)
            
            try await #require(stateModelRef.getters.count == 2)
            
            // when
            try await removeSystem(systemModelRef)
            
            // then
            for getterModel in await stateModelRef.getters.values {
                await #expect(getterModel.isExist == false)
            }
        }
        @Test func deleteSetterModels() async throws {
            // given
            let rootObjectModelRef = try await createRootObject(systemModelRef)
            let stateModelRef = try await createStateModel(rootObjectModelRef)
            
            try await #require(stateModelRef.setters.count == 0)
            
            try await createSetterModel(stateModelRef)
            try await createSetterModel(stateModelRef)
            
            try await #require(stateModelRef.setters.count == 2)
            
            // when
            try await removeSystem(systemModelRef)
            
            // then
            for setterModel in await stateModelRef.setters.values {
                await #expect(setterModel.isExist == false)
            }
        }
        @Test func deleteActionModels() async throws {
            // given
            let rootObjectModelRef = try await createRootObject(systemModelRef)
            
            try await #require(rootObjectModelRef.actions.count == 0)
            
            try await createActionModel(rootObjectModelRef)
            try await createActionModel(rootObjectModelRef)
            
            try await #require(rootObjectModelRef.actions.count == 2)
            
            // when
            try await removeSystem(systemModelRef)
            
            // then
            for actionModel in await rootObjectModelRef.actions.values {
                await #expect(actionModel.isExist == false)
            }
        }
        
        @Test(.disabled("구현 예정")) func deleteFlowModels() async throws { }
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
    try await #require(projectModelRef.systems.count == 1)
    
    let systemModelRef = try #require(await projectModelRef.systems.values.first?.ref)
    return systemModelRef
}

@discardableResult
private func createRootObject(_ systemModelRef: SystemModel) async throws -> ObjectModel {
    await systemModelRef.startUpdating()
    
    await withCheckedContinuation { continuation in
        Task {
            await systemModelRef.setCallback {
                continuation.resume()
            }
            
            await systemModelRef.createRootObject()
        }
    }
    
    let objectModels = await systemModelRef.objects.values
    try #require(objectModels.count == 1)
    
    return try #require(await objectModels.first?.ref)
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


// MARK: Helphers - action
private func removeSystem(_ systemModelRef: SystemModel) async throws {
    try await #require(systemModelRef.isUpdating == true)
    
    await withCheckedContinuation { continuation in
        Task {
            await systemModelRef.setCallback {
                continuation.resume()
            }
            
            await systemModelRef.removeSystem()
        }
    }
}
