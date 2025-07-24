//
//  SetterModelTests.swift
//  BudClient
//
//  Created by 김민우 on 7/23/25.
//
import Foundation
import Testing
import Values
import Collections
@testable import BudClient
@testable import BudServer


// MARK: Tests
@Suite("SetterModel", .timeLimit(.minutes(1)))
struct SetterModelTests {
    struct StartUpdating {
        let budClientRef: BudClient
        let setterModelRef: SetterModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.setterModelRef = try await getSetterModel(budClientRef)
        }
        
        @Test func whenSetterModelIsDeleted() async throws {
            // given
            try await #require(setterModelRef.id.isExist == true)
            
            await setterModelRef.setCaptureHook {
                await setterModelRef.delete()
            }
            
            // when
            await setterModelRef.startUpdating()
            
            // then
            let issue = try #require(await setterModelRef.issue as? KnownIssue)
            #expect(issue.reason == "setterModelIsDeleted")
        }
        
        @Test func setIsUpdatingTrue() async throws {
            // given
            try await #require(setterModelRef.isUpdating == false)
            
            // when
            await setterModelRef.startUpdating()
            
            // then
            try await #require(setterModelRef.issue == nil)
            
            await #expect(setterModelRef.isUpdating == true)
        }
        @Test func whenAlreadyUpdating() async throws {
            // given
            await setterModelRef.startUpdating()
            
            try await #require(setterModelRef.issue == nil)
            
            // when
            await setterModelRef.startUpdating()
            
            // then
            let issue = try #require(await setterModelRef.issue as? KnownIssue)
            #expect(issue.reason == "alreadyUpdating")
        }
    }
    
    struct PushName {
        let budClientRef: BudClient
        let setterModelRef: SetterModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.setterModelRef = try await getSetterModel(budClientRef)
        }
        
        @Test func whenSetterModelIsDeleted() async throws {
            // given
            try await #require(setterModelRef.id.isExist == true)
            
            await setterModelRef.setCaptureHook {
                await setterModelRef.delete()
            }
            
            // when
            await setterModelRef.pushName()
            
            // then
            let issue = try #require(await setterModelRef.issue as? KnownIssue)
            #expect(issue.reason == "setterModelIsDeleted")
        }
    }
    
    struct DuplicateSetter {
        let budClientRef: BudClient
        let setterModelRef: SetterModel
        let stateModelRef: StateModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.setterModelRef = try await getSetterModel(budClientRef)
            self.stateModelRef = try #require(await setterModelRef.config.parent.ref)
        }
        
        @Test func whenSetterModelIsDeleted() async throws {
            // given
            try await #require(setterModelRef.id.isExist == true)
            
            await setterModelRef.setCaptureHook {
                await setterModelRef.delete()
            }
            
            // when
            await setterModelRef.duplicateSetter()
            
            // then
            let issue = try #require(await setterModelRef.issue as? KnownIssue)
            #expect(issue.reason == "setterModelIsDeleted")
        }
        
        @Test func appendSetter_StateModel() async throws {
            // given
            try await #require(stateModelRef.isUpdating == true)
            
            let oldCount = await stateModelRef.setters.count
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await stateModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await setterModelRef.duplicateSetter()
                }
            }
            
            // then
            try await #require(setterModelRef.issue == nil)
            
            let newCount = await stateModelRef.setters.count
            
            #expect(newCount == oldCount + 1)
        }
        @Test func insertSetter_StateModel() async throws {
            // given
            try await #require(stateModelRef.isUpdating == true)
            try await #require(stateModelRef.setters.count == 1)
            
            try await createSetterModel(stateModelRef)
            try await createSetterModel(stateModelRef)
            
            try await #require(stateModelRef.setters.count == 3)
            
            let setters = await stateModelRef.setters.values
            
            // given
            let index = try #require(await stateModelRef.setters.index(forKey: setterModelRef.target))
            
            let newIndex = index.advanced(by: 1)
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await stateModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await setterModelRef.duplicateSetter()
                }
            }
            
            // then
            try await #require(stateModelRef.setters.count == 4)
            
            let newSetterModel = await stateModelRef.setters.values[newIndex]
            
            #expect(setters.contains(newSetterModel) == false)
        }
        @Test func createSetter_StateModel() async throws {
            // given
            try await #require(stateModelRef.isUpdating == true)
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await stateModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await setterModelRef.duplicateSetter()
                }
            }
            
            // then
            let newSetterModel = try #require(await stateModelRef.setters.values.last)
            await #expect(newSetterModel.isExist == true)
        }
    }
    
    struct RemoveSetter {
        let budClientRef: BudClient
        let setterModelRef: SetterModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.setterModelRef = try await getSetterModel(budClientRef)
        }
        
        @Test func whenSetterModelIsDeleted() async throws {
            // given
            try await #require(setterModelRef.id.isExist == true)
            
            await setterModelRef.setCaptureHook {
                await setterModelRef.delete()
            }
            
            // when
            await setterModelRef.removeSetter()
            
            // then
            let issue = try #require(await setterModelRef.issue as? KnownIssue)
            #expect(issue.reason == "setterModelIsDeleted")
        }
        
        @Test func removeSetterModel_StateModel() async throws {
            // given
            let setter = setterModelRef.target
            
            let stateModelRef = try #require(await setterModelRef.config.parent.ref)
            try await #require(stateModelRef.setters[setter] != nil)
            
            await setterModelRef.startUpdating()
            try await #require(setterModelRef.isUpdating == true)
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await setterModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await setterModelRef.removeSetter()
                }
            }
            
            // then
            await #expect(stateModelRef.setters[setter] == nil)
        }
        @Test func deleteSetterModel() async throws {
            // given
            try await #require(setterModelRef.id.isExist == true)
            
            await setterModelRef.startUpdating()
            try await #require(setterModelRef.isUpdating == true)
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await setterModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await setterModelRef.removeSetter()
                }
            }
            
            // then
            await #expect(setterModelRef.id.isExist == false)
        }
    }
}


// MARK: Tests - updater
@Suite("SetterModelUpdater")
struct SetterModelUpdaterTests {
    struct Update {
        let budClientRef: BudClient
        let setterModelRef: SetterModel
        let updaterRef: SetterModel.Updater
        let sourceRef: SetterSourceMock
        init() async throws {
            self.budClientRef = await BudClient()
            self.setterModelRef = try await getSetterModel(budClientRef)
            self.updaterRef = setterModelRef.updaterRef
            self.sourceRef = try #require(await setterModelRef.source.ref as? SetterSourceMock)
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
        @Test func whenSetterModelIsDeleted() async throws {
            // given
            try await #require(setterModelRef.id.isExist == true)
            
            await updaterRef.setMutateHook {
                await setterModelRef.delete()
            }
            
            // when
            await updaterRef.appendEvent(.removed)
            await updaterRef.update()
            
            // then
            try await #require(setterModelRef.id.isExist == false)
            
            let issue = try #require(await updaterRef.issue as? KnownIssue)
            #expect(issue.reason == "setterModelIsDeleted")
        }
        
        @Test func modifySetterModelName() async throws {
            // given
            let oldName = "OLD_NAME"
            let newName = "NEW_NAME"
            
            await MainActor.run {
                setterModelRef.name = oldName
            }
            
            // given
            await sourceRef.setName(newName)
            
            let diff = await SetterSourceDiff(sourceRef)
            
            // when
            await updaterRef.appendEvent(.modified(diff))
            await updaterRef.update()
            
            // then
            await #expect(setterModelRef.name != oldName)
            await #expect(setterModelRef.name == newName)
        }
        @Test func modifySetterModelNameInput() async throws {
            // given
            let oldName = "OLD_NAME"
            let newName = "NEW_NAME"
            
            await MainActor.run {
                setterModelRef.nameInput = oldName
            }
            
            // given
            await sourceRef.setName(newName)
            
            let diff = await SetterSourceDiff(sourceRef)
            
            // when
            await updaterRef.appendEvent(.modified(diff))
            await updaterRef.update()
            
            // then
            await #expect(setterModelRef.nameInput != oldName)
            await #expect(setterModelRef.nameInput == newName)
        }
        
        @Test func modifyParameters() async throws {
            // given
            let oldParameters = OrderedSet<ParameterValue>().toDictionary()
            let newParameters = OrderedSet([
                ParameterValue(name: "name", type: .stringValue)
            ])
            
            await MainActor.run {
                setterModelRef.parameters = oldParameters
            }
            
            // given
            await sourceRef.setParameters(newParameters)
            
            let diff = await SetterSourceDiff(sourceRef)
            
            // when
            await updaterRef.appendEvent(.modified(diff))
            await updaterRef.update()
            
            // then
            await #expect(setterModelRef.parameters != oldParameters)
            await #expect(setterModelRef.parameters == newParameters.toDictionary())
        }
        @Test func modifyParameterInput() async throws {
            // given
            let oldParameters = OrderedSet<ParameterValue>()
            let newParameters = OrderedSet([
                ParameterValue(name: "name", type: .stringValue)
            ])
            
            await MainActor.run {
                setterModelRef.parameterInput = oldParameters
            }
            
            // given
            await sourceRef.setParameters(newParameters)
            
            let diff = await SetterSourceDiff(sourceRef)
            
            // when
            await updaterRef.appendEvent(.modified(diff))
            await updaterRef.update()
            
            // then
            await #expect(setterModelRef.parameterInput != oldParameters)
            await #expect(setterModelRef.parameterInput == newParameters)
        }
        
        @Test func deleteSetterModel() async throws {
            // given
            try await #require(setterModelRef.id.isExist == true)
            
            // when
            await updaterRef.appendEvent(.removed)
            await updaterRef.update()
            
            // then
            await #expect(setterModelRef.id.isExist == false)
        }
        @Test func removeSetterModel_StateModel() async throws {
            // given
            let stateModelRef = try #require(await setterModelRef.config.parent.ref)
            
            try await #require(stateModelRef.setters.values.contains(setterModelRef.id))
            
            // when
            await updaterRef.appendEvent(.removed)
            await updaterRef.update()
            
            // then
            await #expect(stateModelRef.setters.values.contains(setterModelRef.id) == false)
        }
    }
}


// MARK: Helphers
private func getSetterModel(_ budClientRef: BudClient) async throws -> SetterModel {
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
    let stateModelRef = try #require(await rootObjectModelRef.states.values.first?.ref)
    
    // create SetterModel
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
