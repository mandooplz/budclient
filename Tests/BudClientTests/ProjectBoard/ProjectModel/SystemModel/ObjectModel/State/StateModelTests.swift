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
            Issue.record("미구현")
        }
        @Test func receiveInitialEvents_SetterAdded() async throws {
            Issue.record("미구현")
        }
    }
}


@Suite("StateModelUpdater", .timeLimit(.minutes(1)))
struct StateModelUpdaterTests {
    struct Update {
        let budClientRef: BudClient
        let stateModelRef: StateModel
        let updaterRef: StateModel.Updater
        init() async throws {
            self.budClientRef = await BudClient()
            self.stateModelRef = try await getStateModel(budClientRef)
            self.updaterRef = stateModelRef.updaterRef
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
