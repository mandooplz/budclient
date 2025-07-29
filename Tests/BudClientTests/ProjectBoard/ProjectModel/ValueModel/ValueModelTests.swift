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
@Suite("ValueModel")
struct ValueModelTests {
    struct StartUpdating {
        let budClientRef: BudClient
        let valueModelRef: ValueModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.valueModelRef = try await getValueModel(budClientRef)
        }
    }
    
    
    struct RemoveValue {
        let budClientRef: BudClient
        let valueModelRef: ValueModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.valueModelRef = try await getValueModel(budClientRef)
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
    fatalError()
}
