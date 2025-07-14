//
//  SystemModelTests.swift
//  BudClient
//
//  Created by 김민우 on 7/8/25.
//
import Foundation
import Testing
import Values
@testable import BudClient
@testable import BudServer


// MARK: Tests
@Suite("SystemModel", .timeLimit(.minutes(1)))
struct SystemModelTests {
    struct Subscribe {
        let budClientRef: BudClient
        let systemModelRef: SystemModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.systemModelRef = try await getSystemModel(budClientRef)
        }
        
        @Test func whenSystemModelIsDeleted() async throws {
            // given
            try await #require(systemModelRef.id.isExist == true)
            
            // when
            await systemModelRef.subscribe {
                await systemModelRef.delete()
            }
            
            // then
            let issue = try #require(await systemModelRef.issue as? KnownIssue)
            #expect(issue.reason == "systemModelIsDeleted")
        }
        @Test func whenAlreadySubscribed() async throws {
            // given
            await systemModelRef.subscribe()
            try await #require(systemModelRef.issue == nil)
            
            // when
            await systemModelRef.subscribe()
            
            // then
            let issue = try #require(await systemModelRef.issue as? KnownIssue)
            #expect(issue.reason == "alreadySubscribed")
        }
        
        @Test func setHandlerInSystemSource() async throws {
            // given
            let systemSourceRef = try #require(await systemModelRef.source.ref)
            let me = await ObjectID(systemModelRef.id.value)
            
            try await #require(systemSourceRef.hasHandler(requester: me) == false)
            
            // when
            await systemModelRef.subscribe()
            
            // then
            await #expect(systemSourceRef.hasHandler(requester: me) == true)
        }
    }
    
    struct Unsubscribe {
        let budClientRef: BudClient
        let systemModelRef: SystemModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.systemModelRef = try await getSystemModel(budClientRef)
        }
        
        @Test func removeHandlerInSystemSource() async throws {
            // given
            await systemModelRef.subscribe()
            
            let systemSourceRef = try #require(await systemModelRef.source.ref)
            let me = await ObjectID(systemModelRef.id.value)
            try await #require(systemSourceRef.hasHandler(requester: me) == true)
            
            // when
            await systemModelRef.unsubscribe()
            
            // then
            await #expect(systemSourceRef.hasHandler(requester: me) == false)
        }
    }
    
    struct PushName {
        let budClientRef: BudClient
        let systemModelRef: SystemModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.systemModelRef = try await getSystemModel(budClientRef)
        }
        
        @Test func whenSystemModelIsDeleted() async throws {
            // given
            try await #require(systemModelRef.id.isExist == true)
            
            // when
            await systemModelRef.pushName {
                await systemModelRef.delete()
            }
            
            // then
            let issue = try #require(await systemModelRef.issue as? KnownIssue)
            #expect(issue.reason == "systemModelIsDeleted")
        }
        @Test func whenAlreadyUpdated() async throws {
            // given
            let testName = "TEST_NAME_22"
            await MainActor.run {
                systemModelRef.name = testName
                systemModelRef.nameInput = testName
            }
            
            // when
            await systemModelRef.pushName()
            
            // then
            let issue = try #require(await systemModelRef.issue as? KnownIssue)
            #expect(issue.reason == "noChangesToPush")
        }
        
        @Test func modifySystemSourceName() async throws {
            
        }
        @Test func notifyPushEvent() async throws {
            // given
            let testName = "TEST_NAME"
            await MainActor.run {
                systemModelRef.nameInput = testName
            }
            
            try await #require(systemModelRef.name != testName)
            try await #require(systemModelRef.id.isExist == true)
            
            // when
            let projectSourceRef = try #require(await systemModelRef.config.parent.ref)
            
            await withCheckedContinuation { continuation in
                Task {
                    await projectSourceRef.unsubscribe()

                    await projectSourceRef.setCallback {
                        continuation.resume()
                    }
                    await projectSourceRef.subscribe()
                    
                    await systemModelRef.pushName()
                }
            }
            
            // then
            await #expect(systemModelRef.name == testName)
        }
    }
    
    struct AddSystemRight {
        let budClientRef: BudClient
        let systemModelRef: SystemModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.systemModelRef = try await getSystemModel(budClientRef)
        }
        
        @Test func whenSystemModelIsDeleted() async throws {
            
        }
    }
    
    struct Remove {
        let budClientRef: BudClient
        let systemModelRef: SystemModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.systemModelRef = try await getSystemModel(budClientRef)
        }
        
        @Test func whenSystemModelIsDeleted() async throws {
            // given
            try await #require(systemModelRef.id.isExist == true)
            
            // when
            await systemModelRef.remove {
                await systemModelRef.delete()
            }
            
            // then
            let issue = try #require(await systemModelRef.issue as? KnownIssue)
            #expect(issue.reason == "systemModelIsDeleted")
        }
    }
}



// MARK: Helphers
private func getSystemModel(_ budClientRef: BudClient) async throws -> SystemModel {
    // BudClient.setUp()
    await budClientRef.setUp()
    let authBoard = try #require(await budClientRef.authBoard)
    let authBoardRef = try #require(await authBoard.ref)
    
    // AuthBoard.setUpForms()
    await authBoardRef.setUpForms()
    let signInForm = try #require(await authBoardRef.signInForm)
    let signInFormRef = try #require(await signInForm.ref)
    
    // SignInForm.setUpSignUpForm()
    await signInFormRef.setUpSignUpForm()
    let signUpFormRef = try #require(await signInFormRef.signUpForm?.ref)
    
    // SignUpForm.signUp()
    let testEmail = Email.random().value
    let testPassword = Password.random().value
    await MainActor.run {
        signUpFormRef.email = testEmail
        signUpFormRef.password = testPassword
        signUpFormRef.passwordCheck = testPassword
    }
    
    await signUpFormRef.signUp()
    

    // ProjectBoard.createNewProject
    let projectBoardRef = try #require(await budClientRef.projectBoard?.ref)
    
    await withCheckedContinuation { continuation in
        Task {
            await projectBoardRef.setCallback {
                continuation.resume()
            }
            
            await projectBoardRef.subscribe()
            await projectBoardRef.createNewProject()
        }
    }
    
    await projectBoardRef.unsubscribe()
    
    // ProjectEditor.setUp
    await #expect(projectBoardRef.editors.count == 1)
    let projectEditorRef = try #require(await projectBoardRef.editors.first?.ref)
    
    await projectEditorRef.setUp()
    
    // SystemBoard.createFirstSystem
    let systemBoardRef = try #require(await projectEditorRef.systemBoard?.ref)
    
    await withCheckedContinuation { continuation in
        Task {
            await systemBoardRef.setCallback {
                continuation.resume()
            }
            
            await systemBoardRef.subscribe()
            await systemBoardRef.createFirstSystem()
        }
    }
    
    await systemBoardRef.unsubscribe()
    
    // SystemModel
    let systemModelRef = try #require(await systemBoardRef.models.values.first?.ref)
    return systemModelRef
}
