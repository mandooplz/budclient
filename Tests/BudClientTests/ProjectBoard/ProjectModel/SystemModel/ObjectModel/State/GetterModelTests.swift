//
//  GetterModelTests.swift
//  BudClient
//
//  Created by 김민우 on 7/23/25.
//
import Foundation
import Testing
import Values
@testable import BudClient


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
            await withCheckedContinuation { continuation in
                Task {
                    await stateModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await getterModelRef.duplicateGetter()
                }
            }
            
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
            await withCheckedContinuation { continuation in
                Task {
                    await stateModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await getterModelRef.duplicateGetter()
                }
            }
            
            // then
            try await #require(stateModelRef.getters.count == 4)
            
            let newGetterModel = await stateModelRef.getters.values[newIndex]
            
            #expect(getters.contains(newGetterModel) == false)
        }
        @Test func createGetter_StateModel() async throws {
            // given
            try await #require(stateModelRef.isUpdating == true)
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await stateModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await getterModelRef.duplicateGetter()
                }
            }
            
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
