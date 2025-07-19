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
struct ObjectModelTests {
    struct CreateState {
        
    }
    struct CreateAction {
        
    }
    
    struct RemoveObject {
        
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
    await projectBoardRef.setCallbackNil()
    
    await #expect(projectBoardRef.projects.count == 1)

    // ProjectModel.createSystem
    let projectModelRef = try #require(await projectBoardRef.projects.values.first?.ref)
    
    await projectModelRef.startUpdating()
    await withCheckedContinuation { continuation in
        Task {
            await projectModelRef.setCallback {
                continuation.resume()
            }
            
            await projectModelRef.createSystem()
        }
    }
    
    await projectModelRef.setCallbackNil()
    
    // SystemModel
    let systemModelRef = try #require(await projectModelRef.systems.values.first?.ref)
    await systemModelRef.startUpdating()
    
    await withCheckedContinuation { continuation in
        Task {
            await systemModelRef.setCallback {
                continuation.resume()
            }
            
            await systemModelRef.createRoot()
        }
    }
    await systemModelRef.setCallbackNil()
    
    let rootObjectModelRef = try #require(await systemModelRef.root?.ref)
    return rootObjectModelRef
}
