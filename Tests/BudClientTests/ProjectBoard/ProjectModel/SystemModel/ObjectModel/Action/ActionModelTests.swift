//
//  ActionModelTests.swift
//  BudClient
//
//  Created by 김민우 on 7/22/25.
//
import Foundation
import Testing
import Values
@testable import BudClient


// MARK: Tests
@Suite("ActionModel")
struct ActionModelTests {
    struct StartUpdating {
        let budClientRef: BudClient
        let actionModelRef: ActionModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.actionModelRef = try await getActionModel(budClientRef)
        }
        
        @Test func whenActionModelIsDeleted() async throws {
            // given
            try await #require(actionModelRef.id.isExist == true)
            
            await actionModelRef.setCaptureHook {
                await actionModelRef.delete()
            }
            
            // when
            await actionModelRef.startUpdating()
            
            // then
            let issue = try #require(await actionModelRef.issue as? KnownIssue)
            #expect(issue.reason == "actionModelIsDeleted")
        }
    }
    
    struct PushName {
        let budClientRef: BudClient
        let actionModelRef: ActionModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.actionModelRef = try await getActionModel(budClientRef)
        }
        
        @Test func whenActionModelIsDeleted() async throws {
            // given
            try await #require(actionModelRef.id.isExist == true)
            
            await actionModelRef.setCaptureHook {
                await actionModelRef.delete()
            }
            
            // when
            await actionModelRef.pushName()
            
            // then
            let issue = try #require(await actionModelRef.issue as? KnownIssue)
            #expect(issue.reason == "actionModelIsDeleted")
        }
    }
    
    struct DuplicateAction {
        let budClientRef: BudClient
        let actionModelRef: ActionModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.actionModelRef = try await getActionModel(budClientRef)
        }
        
        @Test func whenActionModelIsDeleted() async throws {
            // given
            try await #require(actionModelRef.id.isExist == true)
            
            await actionModelRef.setCaptureHook {
                await actionModelRef.delete()
            }
            
            // when
            await actionModelRef.duplicateAction()
            
            // then
            let issue = try #require(await actionModelRef.issue as? KnownIssue)
            #expect(issue.reason == "actionModelIsDeleted")
        }
    }
    
    struct RemoveAction {
        let budClientRef: BudClient
        let actionModelRef: ActionModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.actionModelRef = try await getActionModel(budClientRef)
        }
        
        @Test func whenActionModelIsDeleted() async throws {
            // given
            try await #require(actionModelRef.id.isExist == true)
            
            await actionModelRef.setCaptureHook {
                await actionModelRef.delete()
            }
            
            // when
            await actionModelRef.removeAction()
            
            // then
            let issue = try #require(await actionModelRef.issue as? KnownIssue)
            #expect(issue.reason == "actionModelIsDeleted")
        }
    }
}


// MARK: Helphers
private func getActionModel(_ budClientRef: BudClient) async throws -> ActionModel {
    // create SignInForm
    await budClientRef.setUp()
    let signInForm = try #require(await budClientRef.signInForm)
    let signInFormRef = try #require(await signInForm.ref)
    
    // create SignUpForm
    await signInFormRef.setUpSignUpForm()
    let signUpFormRef = try #require(await signInFormRef.signUpForm?.ref)
    
    // signup
    let testEmail = Email.random().value
    let testPassword = Password.random().value
    await MainActor.run {
        signUpFormRef.email = testEmail
        signUpFormRef.password = testPassword
        signUpFormRef.passwordCheck = testPassword
    }
    
    await signUpFormRef.submit()
    

    // create ProjectModel
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

    // create SystemModel
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
    
    
    // create ActionModel
    let rootObjectModelRef = try #require(await systemModelRef.root?.ref)
    
    await rootObjectModelRef.startUpdating()
    try await #require(rootObjectModelRef.isUpdating == true)
    try await #require(rootObjectModelRef.actions.count == 0)
    
    await withCheckedContinuation { continuation in
        Task {
            await rootObjectModelRef.setCallback {
                continuation.resume()
            }
            
            await rootObjectModelRef.appendNewAction()
        }
    }
    
    try await #require(rootObjectModelRef.actions.count == 1)
    
    return try #require(await rootObjectModelRef.actions.values.first?.ref)
}
