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
