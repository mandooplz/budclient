//
//  ValueModelTests.swift
//  BudClient
//
//  Created by 김민우 on 7/29/25.
//
import Foundation
import Testing
import Values
@testable import BudClient
@testable import BudServer


// MARK: Tests
@Suite("ValueModel", .timeLimit(.minutes(1)))
struct ValueModelTests {
    struct StartUpdating {
        let budClientRef: BudClient
        let valueModelRef: ValueModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.valueModelRef = try await getValueModel(budClientRef)
        }
        
        @Test func whenValueModelIsDeleted() async throws {
            // given
            try await #require(valueModelRef.id.isExist == true)
            
            await valueModelRef.setCaptureHook {
                await valueModelRef.delete()
            }
            
            // when
            await valueModelRef.startUpdating()
            
            // then
            let issue = try #require(await valueModelRef.issue as? KnownIssue)
            #expect(issue.reason == "valueModelIsDeleted")
        }
        
        @Test func setIsUpdatingTrue() async throws {
            // given
            try await #require(valueModelRef.isUpdating == false)
            
            // when
            await valueModelRef.startUpdating()
            
            // then
            await #expect(valueModelRef.isUpdating == true)
        }
        @Test func whenAlreadyUpdating() async throws {
            // given
            await valueModelRef.startUpdating()
            
            try await #require(valueModelRef.issue == nil)
            
            // when
            await valueModelRef.startUpdating()
            
            // then
            let issue = try #require(await valueModelRef.issue as? KnownIssue)
            #expect(issue.reason == "alreadyUpdating")
        }
    }
    
    
    struct RemoveValue {
        let budClientRef: BudClient
        let valueModelRef: ValueModel
        let projectModelRef: ProjectModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.valueModelRef = try await getValueModel(budClientRef)
            self.projectModelRef = try #require(await valueModelRef.config.parent.ref)
        }
        
        @Test func whenValueModelIsDeleted() async throws {
            // given
            try await #require(valueModelRef.id.isExist == true)
            
            await valueModelRef.setCaptureHook {
                await valueModelRef.delete()
            }
            
            // when
            await valueModelRef.removeValue()
            
            // then
            let issue = try #require(await valueModelRef.issue as? KnownIssue)
            #expect(issue.reason == "valueModelIsDeleted")
        }
        
        @Test func deleteValueModel() async throws {
            // given
            try await #require(valueModelRef.id.isExist == true)
            
            // when
            try await removeValue(valueModelRef)
            
            // then
            await #expect(valueModelRef.id.isExist == false)
        }
        @Test func removeValueModel_ProjectModel() async throws {
            // given
            let target = valueModelRef.target
            
            try await #require(projectModelRef.values[target] != nil)
            
            // when
            try await removeValue(valueModelRef)
            
            // then
            await #expect(projectModelRef.values[target] == nil)
        }
        
        @Test func setTypeNilOfStateValue_StateModel() async throws {
            // given
            let stateModelRef = try await createStateModel(projectModelRef)
            
            let oldValue = StateValue(name: "TEST_STATE",
                                      type: valueModelRef.target)
            let newValue = StateValue(name: "TEST_STATE",
                                      type: nil)
            await MainActor.run {
                stateModelRef.stateValue = oldValue
                stateModelRef.stateValueInput = oldValue
            }
            
            try await #require(stateModelRef.stateValue?.type == valueModelRef.target)
            
            // when
            try await removeValue(valueModelRef)
            
            // then
            try await #require(stateModelRef.stateValue != oldValue)
            
            await #expect(stateModelRef.stateValue == newValue)
            await #expect(stateModelRef.stateValueInput == newValue)
        }
        
        @Test func setTypeNilOfParameterValue_GetterModel() async throws {
            // given
            let stateModelRef = try await createStateModel(projectModelRef)
            
            try await #require(stateModelRef.getters.count == 0)
            
            try await createGetterModel(stateModelRef)
            try await createGetterModel(stateModelRef)
            try await createGetterModel(stateModelRef)
            
            try await #require(stateModelRef.getters.count == 3)
            
            // given
            let oldValue = ParameterValue(name: "TEST_NAME",
                                          type: valueModelRef.target)
            let newValue = oldValue.setType(nil)
            
            for getterModel in await stateModelRef.getters.values {
                let getterModelRef = await getterModel.ref!
                await MainActor.run {
                    getterModelRef.parameters = [oldValue]
                    getterModelRef.parameterInput = [oldValue]
                }
            }
            
            // when
            try await removeValue(valueModelRef)
            
            // then
            for getterModel in await stateModelRef.getters.values {
                let getterModelRef = await getterModel.ref!
                
                await #expect(getterModelRef.parameters == [newValue])
                await #expect(getterModelRef.parameterInput == [newValue])
            }
        }
        @Test func setTypeNilOfResult_GetterModel() async throws {
            // given
            let stateModelRef = try await createStateModel(projectModelRef)
            
            try await #require(stateModelRef.getters.count == 0)
            
            try await createGetterModel(stateModelRef)
            try await createGetterModel(stateModelRef)
            try await createGetterModel(stateModelRef)
            
            try await #require(stateModelRef.getters.count == 3)
            
            // given
            let oldValue = valueModelRef.target
            
            for getterModel in await stateModelRef.getters.values {
                let getterModelRef = await getterModel.ref!
                await MainActor.run {
                    getterModelRef.result = oldValue
                    getterModelRef.resultInput = oldValue
                }
            }
            
            // when
            try await removeValue(valueModelRef)
            
            // then
            for getterModel in await stateModelRef.getters.values {
                let getterModelRef = await getterModel.ref!
                
                await #expect(getterModelRef.result == nil)
                await #expect(getterModelRef.resultInput == nil)
            }
        }

        @Test func setTypeNilOfParameterValue_SetterModel() async throws {
            // given
            let stateModelRef = try await createStateModel(projectModelRef)
            
            try await #require(stateModelRef.setters.count == 0)
            
            try await createSetterModel(stateModelRef)
            try await createSetterModel(stateModelRef)
            try await createSetterModel(stateModelRef)
            
            try await #require(stateModelRef.setters.count == 3)
            
            // given
            let oldValue = ParameterValue(name: "TEST_NAME",
                                          type: valueModelRef.target)
            let newValue = oldValue.setType(nil)
            
            for setterModel in await stateModelRef.setters.values {
                let setterModelRef = await setterModel.ref!
                await MainActor.run {
                    setterModelRef.parameters = [oldValue]
                    setterModelRef.parameterInput = [oldValue]
                }
            }
            
            // when
            try await removeValue(valueModelRef)
            
            // then
            for setterModel in await stateModelRef.setters.values {
                let setterModelRef = await setterModel.ref!
                
                await #expect(setterModelRef.parameters == [newValue])
                await #expect(setterModelRef.parameterInput == [newValue])
            }
        }
    }
}


// MARK: Tests - updater
@Suite("ValueModelUpdater", .timeLimit(.minutes(1)))
struct ValueModelUpdaterTests {
    struct Update {
        let budClientRef: BudClient
        let valueModelRef: ValueModel
        let updaterRef: ValueModel.Updater
        init() async throws {
            self.budClientRef = await BudClient()
            self.valueModelRef = try await getValueModel(budClientRef)
            self.updaterRef = self.valueModelRef.updaterRef
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
        @Test func whenValueModelIsDeleted() async throws {
            // given
            try await #require(valueModelRef.id.isExist ==  true)
            
            await updaterRef.setCaptureHook {
                await valueModelRef.delete()
            }
                        
            // when
            await updaterRef.update()
            
            // then
            let issue = try #require(await updaterRef.issue as? KnownIssue)
            #expect(issue.reason == "valueModelIsDeleted")
        }
        
        // ValueSourceEvent.modified
        
        
        // ValueSourceEvent.removed
        @Test func deleteValueModel() async throws {
            // given
            try await #require(valueModelRef.id.isExist == true)
            
            // when
            await updaterRef.appendEvent(.removed)
            await updaterRef.update()
            
            // then
            await #expect(valueModelRef.id.isExist == false)
        }
        @Test func removeValueModel_ProjectModel() async throws {
            // given
            let projectModelRef = try #require(await valueModelRef.config.parent.ref)
            
            try await #require(projectModelRef.values[valueModelRef.target] != nil)
            
            // when
            await updaterRef.appendEvent(.removed)
            await updaterRef.update()
            
            // then
            await #expect(projectModelRef.values[valueModelRef.target] == nil)
        }
    }
}


// MARK: Helphers
private func getValueModel(_ budClientRef: BudClient) async throws -> ValueModel {
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

    // ProjectModel.createValue
    try await #require(projectBoardRef.projects.count == 1)
    
    let projectModelRef = try #require(await projectBoardRef.projects.values.first?.ref)
    
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
    
    
    // return ValueModel
    try await #require(projectModelRef.values.count == 1)
    
    let valueModelRef = try #require(await projectModelRef.values.values.first?.ref)
    return valueModelRef
}

// MARK: Helpehrs - action
private func removeValue(_ valueModelRef: ValueModel) async throws {
    await valueModelRef.startUpdating()
    try await #require(valueModelRef.isUpdating == true)
    
    await withCheckedContinuation { continuation in
        Task {
            await valueModelRef.setCallback {
                continuation.resume()
            }
            
            await valueModelRef.removeValue()
        }
    }
}

private func createStateModel(_ projectModelRef: ProjectModel) async throws -> StateModel {
    // create SystemModel
    try await #require(projectModelRef.systems.count == 0)
    
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
    
    try await #require(projectModelRef.systems.count == 1)
    
    // create ObjectModel
    let systemModelRef = try #require(await projectModelRef.systems.values.first?.ref)
    try await #require(systemModelRef.objects.count == 0)
    
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
    
    try await #require(systemModelRef.objects.count == 1)
    
    // create StateModel
    let rootObjectModelRef = try #require(await systemModelRef.objects.values.first?.ref)
    try await #require(rootObjectModelRef.states.count == 0)
    
    await rootObjectModelRef.startUpdating()
    try await #require(rootObjectModelRef.isUpdating == true)
    
    await withCheckedContinuation { continuation in
        Task {
            await rootObjectModelRef.setCallback {
                continuation.resume()
            }
            
            await rootObjectModelRef.appendNewState()
        }
    }
    
    try await #require(rootObjectModelRef.states.count == 1)
    
    // return StateModel
    let stateModelRef = try #require(await rootObjectModelRef.states.values.first?.ref)
    return stateModelRef
}
private func createGetterModel(_ stateModelRef: StateModel) async throws {
    
    await stateModelRef.startUpdating()
    try await #require(stateModelRef.isUpdating == true)
    
    await withCheckedContinuation { continuation in
        Task {
            await stateModelRef.setCallback {
                continuation.resume()
            }
            
            await stateModelRef.appendNewGetter()
        }
    }
}

private func createSetterModel(_ stateModelRef: StateModel) async throws {
    await stateModelRef.startUpdating()
    try await #require(stateModelRef.isUpdating == true)
    
    await withCheckedContinuation { continuation in
        Task {
            await stateModelRef.setCallback {
                continuation.resume()
            }
            
            await stateModelRef.appendNewSetter()
        }
    }
}
