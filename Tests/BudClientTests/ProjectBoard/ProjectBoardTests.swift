//
//  ProjectBoardTests.swift
//  BudClient
//
//  Created by 김민우 on 6/26/25.
//
import Testing
import Values
@testable import BudClient
@testable import BudServer


// MARK: Tests
@Suite("ProjectBoard", .timeLimit(.minutes(1)))
struct ProjectBoardTests {
    struct Subscribe {
        let budClientRef: BudClient
        let projectBoardRef: ProjectBoard
        init() async throws {
            self.budClientRef = await BudClient()
            self.projectBoardRef = try await getProjectBoard(budClientRef)
        }
        
        @Test func whenProjectBoardIsDeletedBeforeCapture() async throws {
            // given
            try await #require(projectBoardRef.id.isExist == true)
            
            // when
            await projectBoardRef.subscribe(captureHook: {
                await projectBoardRef.delete()
            })

            // then
            let issue = try #require(await projectBoardRef.issue as? KnownIssue)
            #expect(issue.reason == "projectBoardIsDeleted")
        }
        @Test func whenAlreadySubscribed() async throws {
            // given
            await projectBoardRef.subscribe()
            try await #require(projectBoardRef.issue == nil)
            
            // when
            await projectBoardRef.subscribe()
            
            // then
            let issue = try #require(await projectBoardRef.issue as? KnownIssue)
            #expect(issue.reason == "alreadySubscribed")
        }
        
        @Test func setHandlerInProjectHub() async throws {
            try await newFlowGroup {
                // given
                let config = projectBoardRef.config
                let projectHubRef = try #require(await config.budServer.ref?.projectHub.ref)
                let me = await ObjectID(projectBoardRef.id.value)
                
                try await #require(projectHubRef.hasHandler(requester: me) == false)
                
                // when
                await projectBoardRef.subscribe()
                
                // then
                await #expect(projectHubRef.hasHandler(requester: me) == true)
            }
        }
    }
    
    struct Unsubscribe {
        let budClientRef: BudClient
        let projectBoardRef: ProjectBoard
        init() async throws {
            self.budClientRef = await BudClient()
            self.projectBoardRef = try await getProjectBoard(budClientRef)
        }
        
        @Test func removeHandlerInProjectHub() async throws {
            // given
            let config = projectBoardRef.config
            let projectHubRef = try #require(await config.budServer.ref?.projectHub.ref)
            let me = await ObjectID(projectBoardRef.id.value)
            
            await projectBoardRef.subscribe()
            try await #require(projectHubRef.hasHandler(requester: me) == true)
            
            // when
            await projectBoardRef.unsubscribe()
            
            // then
            await #expect(projectHubRef.hasHandler(requester: me) == false)
        }
    }
    
    struct CreateProject {
        let budClientRef: BudClient
        let projectBoardRef: ProjectBoard
        init() async throws {
            self.budClientRef = await BudClient()
            self.projectBoardRef = try await getProjectBoard(budClientRef)
        }
        
        @Test func whenProjectBoardIsDeletedBeforeCapture() async throws {
            // given
            try await #require(projectBoardRef.id.isExist == true)
            
            // when
            await projectBoardRef.createProject {
                await projectBoardRef.delete()
            }
            
            // then
            try await #require(projectBoardRef.id.isExist == false)
            
            let issue = try #require(await projectBoardRef.issue as? KnownIssue)
            #expect(issue.reason == "projectBoardIsDeleted")
        }
        
        @Test func appendProject() async throws {
            // given
            try await #require(projectBoardRef.editors.isEmpty)
            
            // when
            await withCheckedContinuation { con in
                Task {
                    await projectBoardRef.setCallback {
                        con.resume()
                    }
                    
                    await projectBoardRef.subscribe()
                    await projectBoardRef.createNewProject()
                }
            }

            
            // then
            await projectBoardRef.unsubscribe()
            await #expect(projectBoardRef.editors.count == 1)
            
            // when
            await withCheckedContinuation { con in
                Task.detached {
                    await projectBoardRef.setCallback {
                        con.resume()
                    }
                    
                    await projectBoardRef.subscribe()
                    await projectBoardRef.createNewProject()
                }
            }
            
            
            // then
            await #expect(projectBoardRef.editors.count == 2)
        }
    }
}



// MARK: Helphers
private func getProjectBoard(_ budClientRef: BudClient) async throws -> ProjectBoard {
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
    
    // ProjectBoard
    let projectBoardRef = try #require(await budClientRef.projectBoard?.ref)
    return projectBoardRef
}


