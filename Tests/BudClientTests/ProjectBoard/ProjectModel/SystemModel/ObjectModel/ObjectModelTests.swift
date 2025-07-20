//
//  ObjectModelTests.swift
//  BudClient
//
//  Created by 김민우 on 7/18/25.
//
import Foundation
import Testing
import Values
@testable import BudClient
@testable import BudServer


// MARK: Tests
@Suite("ObjectModel")
struct RootObjectModelTests {
    struct StartUpdating {
        let budClientRef: BudClient
        let objectModelRef: ObjectModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.objectModelRef = try await getRootObjectModel(budClientRef)
        }
        
        @Test func whenObjectModelIsDeleted() async throws {
            // given
            try await #require(objectModelRef.id.isExist == true)
            
            await objectModelRef.setCaptureHook {
                await objectModelRef.delete()
            }
            
            // when
            await objectModelRef.startUpdating()
            
            // then
            let issue = try #require(await objectModelRef.issue as? KnownIssue)
            #expect(issue.reason == "objectModelIsDeleted")
        }
    }
    
    struct PushName {
        
    }
    
    struct addChildObject {
        
    }
    
    struct addParentObject {
        
    }
    
    struct AppendState {
        let budClientRef: BudClient
        let objectModelRef: ObjectModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.objectModelRef = try await getRootObjectModel(budClientRef)
        }
    }
    struct AppendAction {
        let budClientRef: BudClient
        let objectModelRef: ObjectModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.objectModelRef = try await getRootObjectModel(budClientRef)
        }
    }
    
    struct RemoveObject {
        let budClientRef: BudClient
        let objectModelRef: ObjectModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.objectModelRef = try await getRootObjectModel(budClientRef)
        }
    }
}


// MARK: Helphers
private func getRootObjectModel(_ budClientRef: BudClient) async throws-> ObjectModel {
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
    let systemModelRef = try #require(await projectModelRef.systems.values.first?.ref)
    await systemModelRef.startUpdating()
    
    await withCheckedContinuation { continuation in
        Task {
            await systemModelRef.setCallback {
                continuation.resume()
            }
            
            await systemModelRef.createRootObject()
        }
    }
    
    let rootObjectModelRef = try #require(await systemModelRef.root?.ref)
    return rootObjectModelRef
}
