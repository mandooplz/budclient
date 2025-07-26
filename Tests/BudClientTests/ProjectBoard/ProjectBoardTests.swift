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
        let projectHubRef: ProjectHubMock
        init() async throws {
            self.budClientRef = await BudClient()
            self.projectBoardRef = try await getProjectBoard(budClientRef)
            
            let user = projectBoardRef.config.user
            
            self.projectHubRef = await budClientRef
                .tempConfig!.budServer.ref!
                .getProjectHub(user).ref! as! ProjectHubMock
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
        
        @Test func setIsUpdatingTrue() async throws {
            // given
            try await #require(projectBoardRef.isUpdating == false)
            
            // when
            await projectBoardRef.startUpdating()
            
            // then
            await #expect(projectBoardRef.isUpdating == true)
        }
        @Test func whenAlreadyUpdating() async throws {
            // given
            await projectBoardRef.startUpdating()
            
            try await #require(projectBoardRef.issue == nil)
            
            // when
            await projectBoardRef.startUpdating()
            
            // then
            let issue = try #require(await projectBoardRef.issue as? KnownIssue)
            #expect(issue.reason == "alreadyUpdating")
        }
        
        @Test func receiveInitialEvents() async throws {
            // given
            try await #require(projectBoardRef.projects.isEmpty)
            
            await projectBoardRef.createProject()
            
            try await #require(projectBoardRef.projects.isEmpty)
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await projectBoardRef.setCallback {
                        continuation.resume()
                    }
                    
                    await projectBoardRef.startUpdating()
                }
            }
            
            // then
            await #expect(projectBoardRef.projects.count == 1)
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
            }

            // then
            await #expect(projectBoardRef.projects.count == runTime)
        }
    }
}


// MARK: Tests - updater
@Suite("ProjectBoard.Updater", .timeLimit(.minutes(1)))
struct ProjectBoardUpdaterTests {
    struct Update {
        let budClientRef: BudClient
        let projectBoardRef: ProjectBoard
        let updaterRef: ProjectBoard.Updater
        init() async throws {
            self.budClientRef = await BudClient()
            self.projectBoardRef = try await getProjectBoard(budClientRef)
            self.updaterRef = projectBoardRef.updaterRef
        }
        
        @Test func whenProjectModelAlreadyAdded() async throws {
            // given
            await projectBoardRef.startUpdating()
            await withCheckedContinuation { continuation in
                Task {
                    await projectBoardRef.setCallback {
                        continuation.resume()
                    }
                    
                    await projectBoardRef.createProject()
                }
            }
            
            try await #require(projectBoardRef.projects.count == 1)
            
            let projectEditorRef = try #require(await projectBoardRef.projects.values.first?.ref)
            let projectSourceRef = try #require(await projectEditorRef.source.ref)
            
            // when
            let diff = ProjectSourceDiff(
                id: projectSourceRef.id,
                target: projectEditorRef.target,
                name: "DUPLICATE",
                createdAt: .now,
                updatedAt: .now,
                order: 0)
            
            await updaterRef.appendEvent(.added(diff))
            await updaterRef.update()
            
            // then
            await #expect(projectBoardRef.projects.count == 1)
            
            let issue = try #require(await updaterRef.issue as? KnownIssue)
            #expect(issue.reason == "alreadyAdded")
        }
        
        @Test func createProjectModel() async throws {
            // given
            try await #require(projectBoardRef.projects.isEmpty == true)
            
            let newProject = ProjectID()
            let diff = ProjectSourceDiff(
                id: ProjectSourceMock.ID(),
                target: newProject,
                name: "",
                createdAt: .now,
                updatedAt: .now,
                order: 0)
            
            await updaterRef.appendEvent(.added(diff))
            
            // when
            await updaterRef.update()
            
            // then
            try await #require(updaterRef.issue == nil)
            
            try await #require(projectBoardRef.projects.count == 1)
            let projectModel = try #require(await projectBoardRef.projects.values.first)
            let projectModelRef = try #require(await projectModel.ref)
            
            #expect(projectModelRef.target == newProject)
        }
        @Test func removeEventWhenAdded() async throws {
            // given
            let newProject = ProjectID()
            let newProjectSource = ProjectSourceMock.ID()
            
            let diff = ProjectSourceDiff(id: newProjectSource,
                                         target: newProject,
                                         name: "",
                                         createdAt: .now,
                                         updatedAt: .now,
                                         order: 0)
            await updaterRef.appendEvent(.added(diff))
            
            // when
            await updaterRef.update()
            
            // then
            await #expect(updaterRef.queue.isEmpty)
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


