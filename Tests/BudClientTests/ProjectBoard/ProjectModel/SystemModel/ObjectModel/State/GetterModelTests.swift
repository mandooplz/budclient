//
//  GetterModelTests.swift
//  BudClient
//
//  Created by 김민우 on 7/23/25.
//
import Foundation
import Testing
import Collections
import Values
@testable import BudClient
@testable import BudServer

private let logger = BudLogger("GetterModelTests")


// MARK: Tests
@Suite("GetterModel", .timeLimit(.minutes(1)))
struct GetterModelTests {
    struct StartUpdating {
        let budClientRef: BudClient
        let getterModelRef: GetterModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.getterModelRef = try await getGetterModel(budClientRef)
        }
        
        @Test func whenGetterModelIsDeleted() async throws {
            // given
            try await #require(getterModelRef.id.isExist == true)
            
            await getterModelRef.setCaptureHook {
                await getterModelRef.delete()
            }
            
            // when
            await getterModelRef.startUpdating()
            
            // then
            let issue = try #require(await getterModelRef.issue as? KnownIssue)
            #expect(issue.reason == "getterModelIsDeleted")
        }
        
        @Test func setIsUpdatingTrue() async throws {
            // given
            try await #require(getterModelRef.isUpdating == false)
            
            // when
            await getterModelRef.startUpdating()
            
            // then
            try await #require(getterModelRef.issue == nil)
            
            await #expect(getterModelRef.isUpdating == true)
        }
        @Test func whenAlreadyUpdating() async throws {
            // given
            await getterModelRef.startUpdating()
            
            try await #require(getterModelRef.issue == nil)
            
            // when
            await getterModelRef.startUpdating()
            
            // then
            let issue = try #require(await getterModelRef.issue as? KnownIssue)
            #expect(issue.reason == "alreadyUpdating")
        }
    }
    
    struct PushName {
        let budClientRef: BudClient
        let getterModelRef: GetterModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.getterModelRef = try await getGetterModel(budClientRef)
            
            logger.end("테스트 준비 끝")
        }
        
        @Test func whenGetterModelIsDeleted() async throws {
            // given
            try await #require(getterModelRef.id.isExist == true)
            
            await getterModelRef.setCaptureHook {
                await getterModelRef.delete()
            }
            
            // when
            await getterModelRef.pushName()
            
            // then
            let issue = try #require(await getterModelRef.issue as? KnownIssue)
            #expect(issue.reason == "getterModelIsDeleted")
        }
        
        @Test func whenNameInputIsEmpty() async throws {
            // given
            await MainActor.run {
                getterModelRef.nameInput = ""
            }
            
            // when
            await getterModelRef.pushName()
            
            // then
            let issue = try #require(await getterModelRef.issue as? KnownIssue)
            #expect(issue.reason == "nameCannotBeEmpty")
        }
        @Test func whenNameInputIsSameAsCurrent() async throws {
            // given
            let testName = "TEST_GETTER_NAME"
            await MainActor.run {
                getterModelRef.name = testName
                getterModelRef.nameInput = testName
            }
            
            // when
            await getterModelRef.pushName()
            
            // then
            let issue = try #require(await getterModelRef.issue as? KnownIssue)
            #expect(issue.reason == "newNameIsSameAsCurrent")
        }
        
        @Test func updateNameByUpdater() async throws {
            // given
            let oldName = "OLD_NAME"
            let newName = "NEW_NAME"
            
            await MainActor.run {
                getterModelRef.name = oldName
                getterModelRef.nameInput = newName
            }
            
            await getterModelRef.startUpdating()
            try await #require(getterModelRef.isUpdating == true)
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await getterModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await getterModelRef.pushName()
                }
            }
            
            // then
            await #expect(getterModelRef.name != oldName)
            await #expect(getterModelRef.name == newName)
        }
    }
    
    struct PushParameterValues {
        let budClientRef: BudClient
        let getterModelRef: GetterModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.getterModelRef = try await getGetterModel(budClientRef)
        }
        
        @Test func whenGetterModelIsDeleted() async throws {
            // given
            try await #require(getterModelRef.id.isExist == true)
            
            await getterModelRef.setCaptureHook {
                await getterModelRef.delete()
            }
            
            // when
            await getterModelRef.pushParameterValues()
            
            // then
            let issue = try #require(await getterModelRef.issue as? KnownIssue)
            #expect(issue.reason == "getterModelIsDeleted")
        }
        
        @Test func whenParameterInputIsSameAsCurrent() async throws {
            // given
            let parameterValues = await getterModelRef.parameters.keys
            let parameterInput = await getterModelRef.parameterInput
            
            try #require(parameterValues == parameterInput)
            
            // when
            await getterModelRef.pushParameterValues()
            
            // then
            let issue = try #require(await getterModelRef.issue as? KnownIssue)
            #expect(issue.reason == "parametersAreSameAsCurrent")
        }
        @Test func updateParametersByUpdater() async throws {
            // given
            let parameterInput = OrderedSet([
                ParameterValue(name: "name", type: .stringValue),
                ParameterValue(name: "age", type: .intValue)
            ])
            
            await MainActor.run {
                getterModelRef.parameters = [:]
                getterModelRef.parameterInput = parameterInput
            }
            
            await getterModelRef.startUpdating()
            try await #require(getterModelRef.isUpdating == true)
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await getterModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await getterModelRef.pushParameterValues()
                }
            }
            
            // then
            let dict = parameterInput.toDictionary()
            
            await #expect(getterModelRef.parameters == dict)
        }
    }
    
    struct PushResult {
        let budClientRef: BudClient
        let getterModelRef: GetterModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.getterModelRef = try await getGetterModel(budClientRef)
        }
        
        @Test func whenGetterModelIsDeleted() async throws {
            // given
            try await #require(getterModelRef.id.isExist == true)
            
            await getterModelRef.setCaptureHook {
                await getterModelRef.delete()
            }
            
            // when
            await getterModelRef.duplicateGetter()
            
            // then
            let issue = try #require(await getterModelRef.issue as? KnownIssue)
            #expect(issue.reason == "getterModelIsDeleted")
        }
    }
    
    struct DuplicateGetter {
        let budClientRef: BudClient
        let getterModelRef: GetterModel
        let stateModelRef: StateModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.getterModelRef = try await getGetterModel(budClientRef)
            self.stateModelRef = try #require(await getterModelRef.config.parent.ref)
        }
        
        @Test func whenGetterModelIsDeleted() async throws {
            // given
            try await #require(getterModelRef.id.isExist == true)
            
            await getterModelRef.setCaptureHook {
                await getterModelRef.delete()
            }
            
            // when
            await getterModelRef.duplicateGetter()
            
            // then
            let issue = try #require(await getterModelRef.issue as? KnownIssue)
            #expect(issue.reason == "getterModelIsDeleted")
        }
        
        @Test func appendGetter_StateModel() async throws {
            // given
            try await #require(stateModelRef.isUpdating == true)
            
            let oldCount = await stateModelRef.getters.count
            
            // when
            try await duplicateGetter(getterModelRef)
            
            // then
            try await #require(getterModelRef.issue == nil)
            
            let newCount = await stateModelRef.getters.count
            
            #expect(newCount == oldCount + 1)
        }
        @Test func insertGetter_StateModel() async throws {
            // given
            try await #require(stateModelRef.isUpdating == true)
            try await #require(stateModelRef.getters.count == 1)
            
            try await createGetterModel(stateModelRef)
            try await createGetterModel(stateModelRef)
            
            try await #require(stateModelRef.getters.count == 3)
            
            let getters = await stateModelRef.getters.values
            
            // given
            let index = try #require(await stateModelRef.getters.index(forKey: getterModelRef.target))
            
            let newIndex = index.advanced(by: 1)
            
            // when
            try await duplicateGetter(getterModelRef)
            
            // then
            try await #require(stateModelRef.getters.count == 4)
            
            let newGetterModel = await stateModelRef.getters.values[newIndex]
            
            #expect(getters.contains(newGetterModel) == false)
        }
        @Test func createGetter_StateModel() async throws {
            // given
            try await #require(stateModelRef.isUpdating == true)
            
            // when
            try await duplicateGetter(getterModelRef)
            
            // then
            let newGetterModel = try #require(await stateModelRef.getters.values.last)
            await #expect(newGetterModel.isExist == true)
        }
    }
    
    struct RemoveGetter {
        let budClientRef: BudClient
        let getterModelRef: GetterModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.getterModelRef = try await getGetterModel(budClientRef)
        }
        
        @Test func whenGetterModelIsDeleted() async throws {
            // given
            try await #require(getterModelRef.id.isExist == true)
            
            await getterModelRef.setCaptureHook {
                await getterModelRef.delete()
            }
            
            // when
            await getterModelRef.removeGetter()
            
            // then
            let issue = try #require(await getterModelRef.issue as? KnownIssue)
            #expect(issue.reason == "getterModelIsDeleted")
        }
        
        @Test func removeGetterModel_StateModel() async throws {
            // given
            let getter = getterModelRef.target
            
            let stateModelRef = try #require(await getterModelRef.config.parent.ref)
            try await #require(stateModelRef.getters[getter] != nil)
            
            await getterModelRef.startUpdating()
            try await #require(getterModelRef.isUpdating == true)
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await getterModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await getterModelRef.removeGetter()
                }
            }
            
            // then
            await #expect(stateModelRef.getters[getter] == nil)
        }
        @Test func deleteGetterModel() async throws {
            // given
            try await #require(getterModelRef.id.isExist == true)
            
            await getterModelRef.startUpdating()
            try await #require(getterModelRef.isUpdating == true)
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await getterModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await getterModelRef.removeGetter()
                }
            }
            
            // then
            await #expect(getterModelRef.id.isExist == false)
        }
    }
}


// MARK: Tests - updater
@Suite("GetterModelUpdater")
struct GetterModelUpdaterTests {
    struct Update {
        let budClientRef: BudClient
        let getterModelRef: GetterModel
        let sourceRef: GetterSourceMock
        let updaterRef: GetterModel.Updater
        init() async throws {
            self.budClientRef = await BudClient()
            self.getterModelRef = try await getGetterModel(budClientRef)
            self.sourceRef = try #require(await getterModelRef.source.ref as? GetterSourceMock)
            self.updaterRef = getterModelRef.updaterRef
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
        @Test func whenGetterModelIsDeleted() async throws {
            // given
            try await #require(getterModelRef.id.isExist == true)
            
            await updaterRef.setMutateHook {
                await getterModelRef.delete()
            }
            
            // when
            await updaterRef.appendEvent(.removed)
            await updaterRef.update()
            
            // then
            let issue = try #require(await updaterRef.issue as? KnownIssue)
            #expect(issue.reason == "getterModelIsDeleted")
        }
        
        @Test func modifyGetterModelName() async throws {
            // given
            let oldName = "OLD_NAME"
            let newName = "NEW_NAME"
            
            await MainActor.run {
                getterModelRef.name = oldName
            }
            
            // given
            await sourceRef.setName(newName)
            
            let diff = await GetterSourceDiff(sourceRef)
            
            // when
            await updaterRef.appendEvent(.modified(diff))
            await updaterRef.update()
            
            // then
            await #expect(getterModelRef.name != oldName)
            await #expect(getterModelRef.name == newName)
        }
        @Test func modifyGetterModelNameInput() async throws {
            // given
            let oldName = "OLD_NAME"
            let newName = "NEW_NAME"
            
            await MainActor.run {
                getterModelRef.nameInput = oldName
            }
            
            // given
            await sourceRef.setName(newName)
            
            let diff = await GetterSourceDiff(sourceRef)
            
            // when
            await updaterRef.appendEvent(.modified(diff))
            await updaterRef.update()
            
            // then
            await #expect(getterModelRef.nameInput != oldName)
            await #expect(getterModelRef.nameInput == newName)
        }
        
        @Test func modifyParameters() async throws {
            // given
            let oldParameters = OrderedSet<ParameterValue>().toDictionary()
            let newParameters = OrderedSet([
                ParameterValue(name: "name", type: .stringValue)
            ])
            
            await MainActor.run {
                getterModelRef.parameters = oldParameters
            }
            
            // given
            await sourceRef.setParameters(newParameters)
            
            let diff = await GetterSourceDiff(sourceRef)
            
            // when
            await updaterRef.appendEvent(.modified(diff))
            await updaterRef.update()
            
            // then
            await #expect(getterModelRef.parameters != oldParameters)
            await #expect(getterModelRef.parameters == newParameters.toDictionary())
        }
        @Test func modifyParameterInput() async throws {
            // given
            let oldParameters = OrderedSet<ParameterValue>()
            let newParameters = OrderedSet([
                ParameterValue(name: "name", type: .stringValue)
            ])
            
            await MainActor.run {
                getterModelRef.parameterInput = oldParameters
            }
            
            // given
            await sourceRef.setParameters(newParameters)
            
            let diff = await GetterSourceDiff(sourceRef)
            
            // when
            await updaterRef.appendEvent(.modified(diff))
            await updaterRef.update()
            
            // then
            await #expect(getterModelRef.parameterInput != oldParameters)
            await #expect(getterModelRef.parameterInput == newParameters)
        }
        
        @Test func modifyResult() async throws {
            // given
            let oldResult = ValueType.anyValue
            let newResult = ValueType.intValue
            
            await MainActor.run {
                getterModelRef.result = oldResult
            }
            
            // given
            await sourceRef.setResult(newResult)
            
            let diff = await GetterSourceDiff(sourceRef)
            
            // when
            await updaterRef.appendEvent(.modified(diff))
            await updaterRef.update()
            
            // then
            await #expect(getterModelRef.result != oldResult)
            await #expect(getterModelRef.result == newResult)
        }
        @Test func modifyResultInput() async throws {
            // given
            let oldResult = ValueType.anyValue
            let newResult = ValueType.intValue
            
            await MainActor.run {
                getterModelRef.resultInput = oldResult
            }
            
            // given
            await sourceRef.setResult(newResult)
            
            let diff = await GetterSourceDiff(sourceRef)
            
            // when
            await updaterRef.appendEvent(.modified(diff))
            await updaterRef.update()
            
            // then
            await #expect(getterModelRef.resultInput != oldResult)
            await #expect(getterModelRef.resultInput == newResult)
        }
        
        @Test func deleteGetterModel() async throws {
            // given
            try await #require(getterModelRef.id.isExist == true)
            
            // when
            await updaterRef.appendEvent(.removed)
            await updaterRef.update()
            
            // then
            await #expect(getterModelRef.id.isExist == false)
        }
        @Test func removeGetterModel_StateModel() async throws {
            // given
            let stateModelRef = try #require(await getterModelRef.config.parent.ref)
            
            try await #require(stateModelRef.getters.values.contains(getterModelRef.id))
            
            // when
            await updaterRef.appendEvent(.removed)
            await updaterRef.update()
            
            // then
            await #expect(stateModelRef.getters.values.contains(getterModelRef.id) == false)
        }
    }
}


// MARK: Helphers
private func getGetterModel(_ budClientRef: BudClient) async throws-> GetterModel {
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
    
    // create GetterModel
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


// MARK: Helphers - action
private func duplicateGetter(_ getterModelRef: GetterModel) async throws {
    await getterModelRef.startUpdating()
    try await #require(getterModelRef.isUpdating == true)
    
    await withCheckedContinuation { continuation in
        Task {
            await getterModelRef.setCallback {
                continuation.resume()
            }
            
            await getterModelRef.duplicateGetter()
        }
    }
}
