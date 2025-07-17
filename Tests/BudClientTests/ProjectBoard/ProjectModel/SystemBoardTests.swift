//
//  SystemBoardTests.swift
//  BudClient
//
//  Created by 김민우 on 7/7/25.
//
import Foundation
import Testing
import Values
@testable import BudClient
@testable import BudServer


// MARK: Tests
@Suite("SystemBoard", .timeLimit(.minutes(1)))
struct SystemBoardTests {
    struct Subscribe {
        let budClientRef: BudClient
        let systemBoardRef: SystemBoard
        init() async throws {
            self.budClientRef = await BudClient()
            self.systemBoardRef = try await getSystemBoard(budClientRef)
        }
        
        @Test func whenSystemBoardIsDeleted() async throws {
            // given
            try await #require(systemBoardRef.id.isExist == true)
            
            // when
            await systemBoardRef.subscribe {
                await systemBoardRef.delete()
            }
            
            // then
            let issue = try #require(await systemBoardRef.issue)
            #expect(issue.reason == "systemBoardIsDeleted")
        }
        @Test func setHandlerInProjectSource() async throws {
            // given
            let projectEditorRef = try #require(await systemBoardRef.config.parent.ref)
            let projectSourceRef = try #require(await projectEditorRef.source.ref)
            
            let me = await ObjectID(systemBoardRef.id.value)
            
            try await #require(projectSourceRef.hasHandler(requester: me) == false)
            
            // when
            await systemBoardRef.subscribe()
            
            // then
            await #expect(projectSourceRef.hasHandler(requester: me) == true)
        }
        @Test func whenAlreadySubscribed() async throws {
            // given
            await systemBoardRef.subscribe()
            try await #require(systemBoardRef.issue == nil)
            
            // when
            await systemBoardRef.subscribe()
            
            // then
            let issue = try #require(await systemBoardRef.issue as? KnownIssue)
            #expect(issue.reason == "alreadySubscribed")
        }
    }
    
    struct Unsubscribe {
        let budClientRef: BudClient
        let systemBoardRef: SystemBoard
        init() async throws {
            self.budClientRef = await BudClient()
            self.systemBoardRef = try await getSystemBoard(budClientRef)
        }
        
        @Test func removeHandlerInProjectSource() async throws {
            // given
            let projectEditorRef = try #require(await systemBoardRef.config.parent.ref)
            let projectSourceRef = try #require(await projectEditorRef.source.ref)
            
            let me = await ObjectID(systemBoardRef.id.value)
            
            await systemBoardRef.subscribe()
            
            try await #require(projectSourceRef.hasHandler(requester: me) == true)
            
            // when
            await systemBoardRef.unsubscribe()
            
            // then
            await #expect(projectSourceRef.hasHandler(requester: me) == false)
        }
    }
    
    struct CreateFirstSystem {
        let budClientRef: BudClient
        let systemBoardRef: SystemBoard
        init() async throws {
            self.budClientRef = await BudClient()
            self.systemBoardRef = try await getSystemBoard(budClientRef)
        }
        
        @Test func whenSystemBoardIsDeleted() async throws {
            // given
            try await #require(systemBoardRef.id.isExist == true)
            
            // when
            await systemBoardRef.createFirstSystem {
                await systemBoardRef.delete()
            }
            
            // then
            let issue = try #require(await systemBoardRef.issue as? KnownIssue)
            #expect(issue.reason == "systemBoardIsDeleted")
        }
        @Test func whenSystemAlreadyExist() async throws {
            // given
            await withCheckedContinuation { con in
                Task {
                    await systemBoardRef.setCallback {
                        con.resume()
                    }
                    
                    await systemBoardRef.subscribe()
                    await systemBoardRef.createFirstSystem()
                }
            }
            
            try await #require(systemBoardRef.models.isEmpty == false)
            try await #require(systemBoardRef.issue == nil)
            
            // when
            await systemBoardRef.createFirstSystem()
            
            // then
            let issue = try #require(await systemBoardRef.issue as? KnownIssue)
            #expect(issue.reason == "systemAlreadyExist")
        }
        
        @Test func createSystemModel() async throws {
            // given
            try await #require(systemBoardRef.models.isEmpty == true)
            
            await systemBoardRef.unsubscribe()
            
            // when
            await withCheckedContinuation { con in
                Task {
                    await systemBoardRef.setCallback {
                        con.resume()
                    }
                    await systemBoardRef.subscribe()
                    
                    await systemBoardRef.createFirstSystem()
                }
            }
            
            // then
            try await #require(systemBoardRef.models.count == 1)
            
            let systemModel = try #require(await systemBoardRef.models.values.first)
            await #expect(systemModel.isExist == true)
        }
        @Test func createSystemSource() async throws {
            // given
            let projectEditorRef = try #require(await systemBoardRef.config.parent.ref)
            let projectSourceRef = try #require(await projectEditorRef.source.ref as? ProjectSourceMock)
            
            try await #require(projectSourceRef.systems.isEmpty == true)
            
            // when
            await systemBoardRef.createFirstSystem()
            
            // then
            await #expect(projectSourceRef.systems.count == 1)
        }
    }
}



// MARK: Helphers
private func getSystemBoard(_ budClientRef: BudClient) async throws -> SystemBoard {
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
    
    // SystemBoard
    let systemBoardRef = try #require(await projectEditorRef.systemBoard?.ref)
    return systemBoardRef
}

