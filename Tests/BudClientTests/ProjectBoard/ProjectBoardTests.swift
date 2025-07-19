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
    struct StartUpdating {
        let budClientRef: BudClient
        let projectBoardRef: ProjectBoard
        init() async throws {
            self.budClientRef = await BudClient()
            self.projectBoardRef = try await getProjectBoard(budClientRef)
        }
        
        @Test func whenProjectBoardIsDeletedBeforeCapture() async throws {
            // given
            try await #require(projectBoardRef.id.isExist == true)
            
            await projectBoardRef.setCaptureHook {
                await projectBoardRef.delete()
            }
            
            // when
            await projectBoardRef.startUpdating()

            // then
            let issue = try #require(await projectBoardRef.issue as? KnownIssue)
            #expect(issue.reason == "projectBoardIsDeleted")
        }
        
        @Test func setHandler_ProjectHub() async throws {
            // given
            let budServerRef = try #require(await budClientRef.tempConfig?.budServer.ref)
            let projectHubRef = try #require(await budServerRef.getProjectHub(projectBoardRef.config.user).ref as? ProjectHubMock)
            
            try await #require(projectHubRef.handler == nil)
            
            // when
            await projectBoardRef.startUpdating()
            
            // then
            await #expect(projectHubRef.handler != nil)
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
            
            await projectBoardRef.setCaptureHook {
                await projectBoardRef.delete()
            }
            
            // when
            await projectBoardRef.createProject()
            
            // then
            try await #require(projectBoardRef.id.isExist == false)
            
            let issue = try #require(await projectBoardRef.issue as? KnownIssue)
            #expect(issue.reason == "projectBoardIsDeleted")
        }
        
        @Test func appendProject() async throws {
            // given
            try await #require(projectBoardRef.projects.isEmpty)
            
            // when
            let runTime = 5

            await projectBoardRef.startUpdating()
            for _ in 1...runTime {
                await withCheckedContinuation { continuation in
                    Task {
                        await projectBoardRef.setCallback {
                            continuation.resume()
                        }
                        
                        await projectBoardRef.createProject()
                    }
                }
                
                await projectBoardRef.setCallbackNil()
            }

            // then
            await #expect(projectBoardRef.projects.count == runTime)
        }
    }
}



// MARK: Helphers
private func getProjectBoard(_ budClientRef: BudClient) async throws -> ProjectBoard {
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
    
    // ProjectBoard
    let projectBoardRef = try #require(await budClientRef.projectBoard?.ref)
    return projectBoardRef
}


