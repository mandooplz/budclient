//
//  StateModelTests.swift
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
@Suite("StateModel", .timeLimit(.minutes(1)))
struct StateModelTests {
    struct StartUpdating {
        let budClientRef: BudClient
        let stateModelRef: StateModel
        let stateSourceRef: StateSourceMock
        init() async throws {
            self.budClientRef = await BudClient()
            self.stateModelRef = try await getStateModel(budClientRef)
            self.stateSourceRef = try #require(await stateModelRef.source.ref as? StateSourceMock)
        }
        
        @Test func whenStateModelIsDeleted() async throws {
            // given
            try await #require(stateModelRef.id.isExist == true)
            
            await stateModelRef.setCaptureHook {
                await stateModelRef.delete()
            }
            
            // when
            await stateModelRef.startUpdating()
            
            // then
            let issue = try #require(await stateModelRef.issue as? KnownIssue)
            #expect(issue.reason == "stateModelIsDeleted")
        }
        
        @Test func setIsUpdatingTrue() async throws {
            // given
            try await #require(stateModelRef.isUpdating == false)
            
            // when
            await stateModelRef.startUpdating()
            
            // then
            await #expect(stateModelRef.isUpdating == true)
        }
        @Test func whenAlreadyUpdating() async throws {
            // given
            await stateModelRef.startUpdating()
            await #expect(stateModelRef.isUpdating == true)
            
            // when
            await stateModelRef.startUpdating()
            
            // then
            let issue = try #require(await stateModelRef.issue as? KnownIssue)
            #expect(issue.reason == "alreadyUpdating")
        }
        
        @Test func recevieInitialEvents_GetterAdded() async throws {
            // given
            try await #require(stateSourceRef.getters.count == 0)
            try await #require(stateModelRef.getters.isEmpty)
            
            await stateSourceRef.appendNewGetter()
            
            try await #require(stateSourceRef.getters.count == 1)
            try await #require(stateModelRef.getters.isEmpty)
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await stateModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await stateModelRef.startUpdating()
                }
            }
            
            // then
            await #expect(stateModelRef.getters.count == 1)
        }
        @Test func receiveInitialEvents_SetterAdded() async throws {
            // given
            try await #require(stateSourceRef.setters.count == 0)
            try await #require(stateModelRef.setters.isEmpty)
            
            await stateSourceRef.appendNewSetter()
            
            try await #require(stateSourceRef.setters.count == 1)
            try await #require(stateModelRef.setters.isEmpty)
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await stateModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await stateModelRef.startUpdating()
                }
            }
            
            // then
            await #expect(stateModelRef.setters.count == 1)
        }
    }
    
    struct PushName {
        let budClientRef: BudClient
        let stateModelRef: StateModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.stateModelRef = try await getStateModel(budClientRef)
        }
        
        @Test func whenStateModelIsDeleted() async throws {
            // given
            try await #require(stateModelRef.id.isExist == true)
            
            await stateModelRef.setCaptureHook {
                await stateModelRef.delete()
            }
            
            // when
            await stateModelRef.pushName()
            
            // then
            let issue = try #require(await stateModelRef.issue as? KnownIssue)
            #expect(issue.reason == "stateModelIsDeleted")
        }
        
        @Test func whenNameInputIsEmpty() async throws {
            // given
            await MainActor.run {
                stateModelRef.nameInput = ""
            }
            
            try await #require(stateModelRef.issue == nil)
            
            // when
            await stateModelRef.pushName()
            
            // then
            let issue = try #require(await stateModelRef.issue as? KnownIssue)
            #expect(issue.reason == "nameCannotBeEmpty")
        }
        @Test func whenNameInputIsSameWithName() async throws {
            // given
            let testName = "TEST_NAME"
            await MainActor.run {
                stateModelRef.name = testName
                stateModelRef.nameInput = testName
            }
            
            try await #require(stateModelRef.issue == nil)
            
            // when
            await stateModelRef.pushName()
            
            // then
            let issue = try #require(await stateModelRef.issue as? KnownIssue)
            #expect(issue.reason == "newNameIsSameAsCurrent")
        }
        
        @Test func updateNamebyUpdater() async throws {
            // given
            let oldName = "OLD_NAME"
            let newName = "NEW_NAME"
            
            await MainActor.run {
                stateModelRef.name = oldName
                stateModelRef.nameInput = newName
            }
            
            await stateModelRef.startUpdating()
            try await #require(stateModelRef.isUpdating == true)
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await stateModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await stateModelRef.pushName()
                }
            }
            
            // then
            try await #require(stateModelRef.issue == nil)
            
            await #expect(stateModelRef.name != oldName)
            await #expect(stateModelRef.name == newName)
        }
    }
    
    struct PushAccessLevel {
        let budClientRef: BudClient
        let stateModelRef: StateModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.stateModelRef = try await getStateModel(budClientRef)
        }
        
        @Test func whenStateModelIsDeleted() async throws {
            // given
            try await #require(stateModelRef.id.isExist == true)
            
            await stateModelRef.setCaptureHook {
                await stateModelRef.delete()
            }
            
            // when
            await stateModelRef.pushAccessLevel()
            
            // then
            let issue = try #require(await stateModelRef.issue as? KnownIssue)
            #expect(issue.reason == "stateModelIsDeleted")
        }
        
        @Test func whenAccessLevelInputIsSameAsCurrent() async throws {
            // given
            await MainActor.run {
                stateModelRef.accessLevel = .readOnly
                stateModelRef.accessLevelInput = .readOnly
            }
            
            // when
            await stateModelRef.pushAccessLevel()
            
            // then
            let issue = try #require(await stateModelRef.issue as? KnownIssue)
            #expect(issue.reason == "accessLevelIsSameAsCurrent")
        }
        
        @Test func updateAccessLevelByUpdater() async throws {
            // given
            let oldValue = AccessLevel.readOnly
            let newValue = AccessLevel.readAndWrite
            await MainActor.run {
                stateModelRef.accessLevel = .readOnly
                stateModelRef.accessLevelInput = .readAndWrite
            }
            
            await stateModelRef.startUpdating()
            try await #require(stateModelRef.isUpdating == true)
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await stateModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await stateModelRef.pushAccessLevel()
                }
            }
            
            // then
            await #expect(stateModelRef.accessLevel == newValue)
            await #expect(stateModelRef.accessLevel != oldValue)
        }
    }
    
    struct PushStateValue {
        let budClientRef: BudClient
        let stateModelRef: StateModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.stateModelRef = try await getStateModel(budClientRef)
        }
        
        @Test func whenStateModelIsDeleted() async throws {
            // given
            try await #require(stateModelRef.id.isExist == true)
            
            await stateModelRef.setCaptureHook {
                await stateModelRef.delete()
            }
            
            // when
            await stateModelRef.pushStateValue()
            
            // then
            let issue = try #require(await stateModelRef.issue as? KnownIssue)
            #expect(issue.reason == "stateModelIsDeleted")
        }
        
        @Test func whenStateValueInputIsSameAsCurrent() async throws {
            // given
            await MainActor.run {
                stateModelRef.stateValue = .anyState
                stateModelRef.stateValueInput = .anyState
            }
            
            // when
            await stateModelRef.pushStateValue()
            
            // then
            let issue = try #require(await stateModelRef.issue as? KnownIssue)
            #expect(issue.reason == "stateValueIsSameAsCurrent")
        }
        
        @Test func updateStateValueByUpdater() async throws {
            // given
            let oldValue = StateValue.anyState
            let newValue = StateValue(name: "new_state",
                                      type: .init(name: "NEW_STATE"))
            await MainActor.run {
                stateModelRef.stateValue = oldValue
                stateModelRef.stateValueInput = newValue
            }
            
            await stateModelRef.startUpdating()
            try await #require(stateModelRef.isUpdating == true)
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await stateModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await stateModelRef.pushStateValue()
                }
            }
            
            // then
            await #expect(stateModelRef.stateValue == newValue)
            await #expect(stateModelRef.stateValue != oldValue)
        }
    }
    
    struct AppendNewGetter {
        let budClientRef: BudClient
        let stateModelRef: StateModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.stateModelRef = try await getStateModel(budClientRef)
        }
        
        @Test func whenStateModelIsDeleted() async throws {
            // given
            try await #require(stateModelRef.id.isExist == true)
            
            await stateModelRef.setCaptureHook {
                await stateModelRef.delete()
            }
            
            // when
            await stateModelRef.appendNewGetter()
            
            // then
            let issue = try #require(await stateModelRef.issue as? KnownIssue)
            #expect(issue.reason == "stateModelIsDeleted")
        }
        
        @Test func appendGetterModel() async throws {
            // given
            try await #require(stateModelRef.getters.isEmpty)
            
            await stateModelRef.startUpdating()
            try await #require(stateModelRef.isUpdating == true)
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await stateModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await stateModelRef.appendNewGetter()
                }
            }
            
            // then
            try await #require(stateModelRef.issue == nil)
            
            await #expect(stateModelRef.getters.count == 1)
        }
        @Test func createGetterModel() async throws {
            // given
            try await #require(stateModelRef.getters.isEmpty)
            
            await stateModelRef.startUpdating()
            try await #require(stateModelRef.isUpdating == true)
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await stateModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await stateModelRef.appendNewGetter()
                }
            }
            
            // then
            try await #require(stateModelRef.issue == nil)
            try await #require(stateModelRef.getters.count == 1)
            
            let getterModel = try #require(await stateModelRef.getters.values.first)
            await #expect(getterModel.isExist == true)
        }
    }
    
    struct AppendNewSetter {
        let budClientRef: BudClient
        let stateModelRef: StateModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.stateModelRef = try await getStateModel(budClientRef)
        }
        
        @Test func whenStateModelIsDeleted() async throws {
            // given
            try await #require(stateModelRef.id.isExist == true)
            
            await stateModelRef.setCaptureHook {
                await stateModelRef.delete()
            }
            
            // when
            await stateModelRef.appendNewSetter()
            
            // then
            let issue = try #require(await stateModelRef.issue as? KnownIssue)
            #expect(issue.reason == "stateModelIsDeleted")
        }
        
        @Test func appendSetterModel() async throws {
            // given
            try await #require(stateModelRef.setters.isEmpty)
            
            await stateModelRef.startUpdating()
            try await #require(stateModelRef.isUpdating == true)
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await stateModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await stateModelRef.appendNewSetter()
                }
            }
            
            // then
            try await #require(stateModelRef.issue == nil)
            
            await #expect(stateModelRef.setters.count == 1)
        }
        @Test func createSetterModel() async throws {
            // given
            try await #require(stateModelRef.setters.isEmpty)
            
            await stateModelRef.startUpdating()
            try await #require(stateModelRef.isUpdating == true)
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await stateModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await stateModelRef.appendNewSetter()
                }
            }
            
            // then
            try await #require(stateModelRef.issue == nil)
            try await #require(stateModelRef.setters.count == 1)
            
            let setterModel = try #require(await stateModelRef.setters.values.first)
            await #expect(setterModel.isExist == true)
        }
    }
    
    struct DuplicateState {
        let budClientRef: BudClient
        let stateModelRef: StateModel
        let objectModelRef: ObjectModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.stateModelRef = try await getStateModel(budClientRef)
            self.objectModelRef = try #require(await stateModelRef.config.parent.ref)
        }
        
        @Test func whenStateModelIsDeleted() async throws {
            // given
            try await #require(stateModelRef.id.isExist == true)
            
            await stateModelRef.setCaptureHook {
                await stateModelRef.delete()
            }
            
            // when
            await stateModelRef.duplicateState()
            
            // then
            let issue = try #require(await stateModelRef.issue as? KnownIssue)
            #expect(issue.reason == "stateModelIsDeleted")
        }
        
        @Test func appendStateModel_ObjectModel() async throws {
            // given
            try await #require(objectModelRef.isUpdating == true)
            
            let oldCount = await objectModelRef.states.count
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await objectModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await stateModelRef.duplicateState()
                }
            }
            
            // then
            try await #require(stateModelRef.issue == nil)
            
            let newCount = await objectModelRef.states.count
            
            #expect(newCount == oldCount + 1)
        }
        @Test func insertStateModel_ObjectModel() async throws {
            // given
            try await #require(objectModelRef.isUpdating == true)
            try await #require(objectModelRef.states.count == 1)
            
            try await createNewStateModel(objectModelRef)
            try await createNewStateModel(objectModelRef)
            
            try await #require(objectModelRef.states.count == 3)
            
            let states = await objectModelRef.states.values
            
            // given
            let index = try #require(await objectModelRef.states.index(forKey: stateModelRef.target))
            
            let newIndex = index.advanced(by: 1)
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await objectModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await stateModelRef.duplicateState()
                }
            }
            
            // then
            try await #require(objectModelRef.states.count == 4)
            
            let newStateModel = await  objectModelRef.states.values[newIndex]
            
            #expect(states.contains(newStateModel) == false)
        }
        @Test func createStateModel_ObjectModel() async throws {
            // given
            try await #require(objectModelRef.isUpdating == true)
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await objectModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await stateModelRef.duplicateState()
                }
            }
            
            // then
            let newStateModel = try #require(await objectModelRef.states.values.last)
            await #expect(newStateModel.isExist == true)
        }
        
        @Test func duplicateName() async throws {
            // given
            try await #require(objectModelRef.isUpdating == true)
            
            let originalName = await stateModelRef.name
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await objectModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await stateModelRef.duplicateState()
                }
            }
            
            // then
            let newStateModelRef = try #require(await objectModelRef.states.values.last?.ref)
            
            await #expect(newStateModelRef.name == originalName)
        }
        @Test func duplicateAccessLevel() async throws {
            // given
            try await #require(objectModelRef.isUpdating == true)
            
            let original = await stateModelRef.accessLevel
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await objectModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await stateModelRef.duplicateState()
                }
            }
            
            // then
            let newStateModelRef = try #require(await objectModelRef.states.values.last?.ref)
            
            await #expect(newStateModelRef.accessLevel == original)
        }
        @Test func duplicateStateValue() async throws {
            // given
            try await #require(objectModelRef.isUpdating == true)
            
            let original = await stateModelRef.stateValue
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await objectModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await stateModelRef.duplicateState()
                }
            }
            
            // then
            let newStateModelRef = try #require(await objectModelRef.states.values.last?.ref)
            
            await #expect(newStateModelRef.stateValue == original)
        }
    }
    
    struct RemoveState {
        let budClientRef: BudClient
        let stateModelRef: StateModel
        let objectModelRef: ObjectModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.stateModelRef = try await getStateModel(budClientRef)
            self.objectModelRef = try #require(await stateModelRef.config.parent.ref)
        }
        
        @Test func whenStateModelIsDeleted() async throws {
            // given
            try await #require(stateModelRef.id.isExist == true)
            
            await stateModelRef.setCaptureHook {
                await stateModelRef.delete()
            }
            
            // when
            await stateModelRef.removeState()
            
            // then
            let issue = try #require(await stateModelRef.issue as? KnownIssue)
            #expect(issue.reason == "stateModelIsDeleted")
        }
        
        @Test func deleteStateModel() async throws {
            // given
            try await #require(stateModelRef.id.isExist == true)
            
            await stateModelRef.startUpdating()
            try await #require(stateModelRef.isUpdating == true)
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await stateModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await stateModelRef.removeState()
                }
            }
            
            // then
            await #expect(stateModelRef.id.isExist == false)
            
        }
        @Test func removeStateModel_ObjectModel() async throws {
            // given
            let myTarget = stateModelRef.target
            try await #require(objectModelRef.states[myTarget] != nil)
            
            await stateModelRef.startUpdating()
            try await #require(stateModelRef.isUpdating == true)
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await stateModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await stateModelRef.removeState()
                }
            }
            
            // then
            await #expect(objectModelRef.states[myTarget] == nil)
        }
        
        @Test func deleteGetterModels() async throws {
            // given
            await stateModelRef.startUpdating()
            try await #require(stateModelRef.isUpdating == true)
            
            // given
            try await #require(stateModelRef.getters.isEmpty)
            
            try await createGetterModel(stateModelRef)
            try await createGetterModel(stateModelRef)
            
            try await #require(stateModelRef.getters.count == 2)
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await stateModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await stateModelRef.removeState()
                }
            }
            
            // then
            for getterModel in await stateModelRef.getters.values {
                await #expect(getterModel.isExist == false)
            }
        }
        @Test func deleteSetterModels() async throws {
            // given
            await stateModelRef.startUpdating()
            try await #require(stateModelRef.isUpdating == true)
            
            // given
            try await #require(stateModelRef.setters.isEmpty)
            
            try await createSetterModel(stateModelRef)
            try await createSetterModel(stateModelRef)
            
            try await #require(stateModelRef.setters.count == 2)
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await stateModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await stateModelRef.removeState()
                }
            }
            
            // then
            for setterModel in await stateModelRef.setters.values {
                await #expect(setterModel.isExist == false)
            }
        }
    }
}


@Suite("StateModelUpdater", .timeLimit(.minutes(1)))
struct StateModelUpdaterTests {
    struct Update {
        let budClientRef: BudClient
        let stateModelRef: StateModel
        let sourceRef: StateSourceMock
        let updaterRef: StateModel.Updater
        init() async throws {
            self.budClientRef = await BudClient()
            self.stateModelRef = try await getStateModel(budClientRef)
            self.sourceRef = try #require(await stateModelRef.source.ref as? StateSourceMock)
            self.updaterRef = stateModelRef.updaterRef
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
        @Test func whenStateModelIsDeleted() async throws {
            // given
            try await #require(stateModelRef.id.isExist == true)
            
            await updaterRef.setCaptureHook {
                await stateModelRef.delete()
            }
            
            // when
            await updaterRef.appendEvent(.removed)
            await updaterRef.update()
            
            // then
            let issue = try #require(await updaterRef.issue as? KnownIssue)
            #expect(issue.reason == "stateModelIsDeleted")
        }
        
        @Test func modifyStateModelName() async throws {
            // given
            let oldName = "OLD_NAME"
            let newName = "NEW_NAME"
            
            await MainActor.run {
                stateModelRef.name = oldName
            }
            
            // given
            await sourceRef.setName(newName)
            
            let diff = await StateSourceDiff(sourceRef)
            
            // when
            await updaterRef.appendEvent(.modified(diff))
            await updaterRef.update()
            
            // then
            await #expect(stateModelRef.name != oldName)
            await #expect(stateModelRef.name == newName)
        }
        @Test func modifyStateModelNameInput() async throws {
            // given
            let oldName = "OLD_NAME"
            let newName = "NEW_NAME"
            
            await MainActor.run {
                stateModelRef.nameInput = oldName
            }
            
            // given
            await sourceRef.setName(newName)
            
            let diff = await StateSourceDiff(sourceRef)
            
            // when
            await updaterRef.appendEvent(.modified(diff))
            await updaterRef.update()
            
            // then
            await #expect(stateModelRef.nameInput != oldName)
            await #expect(stateModelRef.nameInput == newName)
        }
        
        @Test func deleteStateModel() async throws {
            // given
            try await #require(stateModelRef.id.isExist == true)
            
            // when
            await updaterRef.appendEvent(.removed)
            await updaterRef.update()
            
            // then
            await #expect(stateModelRef.id.isExist == false)
        }
        @Test func removeStateModel_ObjectModel() async throws {
            // given
            let objectModelRef = try #require(await stateModelRef.config.parent.ref)
            
            try await #require(objectModelRef.states.values.contains(stateModelRef.id))
            
            // when
            await updaterRef.appendEvent(.removed)
            await updaterRef.update()
            
            // then
            await #expect(objectModelRef.states.values.contains(stateModelRef.id) == false)
        }
    }
}



// MARK: Helphers
private func getStateModel(_ budClientRef: BudClient) async throws-> StateModel {
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

    // ProjectModel.createFirstSystem
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
    
    
    // create StateModel
    let rootObjectModelRef = try #require(await systemModelRef.root?.ref)
    
    await rootObjectModelRef.startUpdating()
    try await #require(rootObjectModelRef.isUpdating == true)
    try await #require(rootObjectModelRef.states.count == 0)
    
    await withCheckedContinuation { continuation in
        Task {
            await rootObjectModelRef.setCallback {
                continuation.resume()
            }
            
            await rootObjectModelRef.appendNewState()
        }
    }
    
    try await #require(rootObjectModelRef.states.count == 1)
    
    return try #require(await rootObjectModelRef.states.values.first?.ref)
}

private func createNewStateModel(_ objectModelRef: ObjectModel) async throws {
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

