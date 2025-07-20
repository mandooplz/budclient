//
//  ProjectModelTests.swift
//  BudClient
//
//  Created by 김민우 on 7/1/25.
//
import Foundation
import Testing
import Values
@testable import BudClient
@testable import BudServer


// MARK: Tests
@Suite("ProjectModel", .timeLimit(.minutes(1)))
struct ProjectModelTests {
    struct StartUpdating {
        let budClientRef: BudClient
        let projectModelRef: ProjectModel
        let projectSourceRef: ProjectSourceMock
        init() async throws {
            self.budClientRef = await BudClient()
            self.projectModelRef = try await getProjectModel(budClientRef)
            self.projectSourceRef = await projectModelRef.source.ref as! ProjectSourceMock
        }
        
        @Test func whenProjectModelIsDeleted() async throws {
            // given
            try await #require(projectModelRef.id.isExist == true)
            
            await projectModelRef.setCaptureHook {
                await projectModelRef.delete()
            }
            
            // when
            await projectModelRef.startUpdating()
            
            // then
            let issue = try #require(await projectModelRef.issue as? KnownIssue)
            #expect(issue.reason == "projectModelIsDeleted")
            
        }
        
        @Test func receiveInitialEvents() async throws {
            // given
            try await #require(projectModelRef.systems.isEmpty)
            try await #require(projectSourceRef.systems.isEmpty)
            
            await projectModelRef.createFirstSystem()
            
            try await #require(projectModelRef.systems.isEmpty)
            try await #require(projectSourceRef.systems.count == 1)
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await projectModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await projectModelRef.startUpdating()
                }
            }
            
            // then
            await #expect(projectModelRef.systems.count == 1)
        }
    }
    
    struct PushName {
        let budClientRef: BudClient
        let projectModelRef: ProjectModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.projectModelRef = try await getProjectModel(budClientRef)
        }
        
        @Test func whenProjectModelIsDeleted() async throws {
            // given
            try await #require(projectModelRef.id.isExist == true)
            
            await projectModelRef.setCaptureHook {
                await projectModelRef.delete()
            }
            
            // when
            await projectModelRef.pushName()
            
            // then
            let issue = try #require(await projectModelRef.issue)
            #expect(issue.reason == "projectModelIsDeleted")
        }
        
        @Test func whenNameInputIsEmpty() async throws {
            // given
            await MainActor.run {
                projectModelRef.nameInput = ""
            }
            
            // when
            await projectModelRef.pushName()
            
            // then
            let issue = try #require(await projectModelRef.issue as? KnownIssue)
            #expect(issue.reason == "nameCannotBeEmpty")
        }
        @Test func whenNameInputIsSameWithName() async throws {
            // given
            await MainActor.run {
                projectModelRef.nameInput = "TEST"
                projectModelRef.name = "TEST"
            }
            
            // when
            await projectModelRef.pushName()
            
            // then
            let issue = try #require(await projectModelRef.issue as? KnownIssue)
            #expect(issue.reason == "newNameIsSameAsCurrent")
        }
        
        @Test func updateNameByHandler() async throws {
            // given
            let testName = "TEST_PROJECT_NAME"
            
            await MainActor.run {
                projectModelRef.nameInput = testName
            }
            
            // then
            await projectModelRef.startUpdating()
            await withCheckedContinuation { continuation in
                Task {
                    await projectModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await projectModelRef.pushName()
                }
            }
            
            
            // then
            await #expect(projectModelRef.name == testName)
        }
    }
    
    struct CreateFirstSystem {
        let budClientRef: BudClient
        let projectModelRef: ProjectModel
        let projectSourceRef: ProjectSourceMock
        init() async throws {
            self.budClientRef = await BudClient()
            self.projectModelRef = try await getProjectModel(budClientRef)
            self.projectSourceRef = await projectModelRef.source.ref as! ProjectSourceMock
        }
        
        @Test func whenProjectModelIsDeleted() async throws {
            // given
            try await #require(projectModelRef.id.isExist == true)
            
            await projectModelRef.setCaptureHook {
                await projectModelRef.delete()
            }
            // when
            await projectModelRef.createFirstSystem()
            
            // then
            let issue = try #require(await projectModelRef.issue as? KnownIssue)
            #expect(issue.reason == "projectModelIsDeleted")
        }
        
        @Test func createSystemModel() async throws {
            // given
            try await #require(projectModelRef.systems.isEmpty == true)
            try await #require(projectSourceRef.systems.isEmpty)
            
            await projectModelRef.startUpdating()
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await projectModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await projectModelRef.createFirstSystem()
                }
            }
            
            // then
            try await #require(projectModelRef.systems.count == 1)
            
            let systemModel = try #require(await projectModelRef.systems.values.first)
            await #expect(systemModel.isExist == true)
        }
        @Test func createSystemSource() async throws {
            // given
            let projectSourceRef = try #require(await projectModelRef.source.ref as? ProjectSourceMock)
            
            try await #require(projectSourceRef.systems.isEmpty == true)
            
            // when
            await projectModelRef.createFirstSystem()
            
            // then
            await #expect(projectSourceRef.systems.count == 1)
        }
        
        @Test func whenFirstSystemAlreadyExist() async throws {
            // given
            try await #require(projectModelRef.systems.isEmpty)
            
            await projectModelRef.startUpdating()
            await withCheckedContinuation { continuation in
                Task {
                    await projectModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await projectModelRef.createFirstSystem()
                }
            }
            
            try await #require(projectModelRef.systems.count == 1)
            try await #require(projectModelRef.issue == nil)
            
            // when
            await projectModelRef.createFirstSystem()
            
            // then
            try await #require(projectModelRef.systems.count == 1)
            
            let issue = try #require(await projectModelRef.issue as? KnownIssue)
            #expect(issue.reason == "firstSystemAlreadyExist")
        }
    }

    struct RemoveProject {
        let budClientRef: BudClient
        let projectModelRef: ProjectModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.projectModelRef = try await getProjectModel(budClientRef)
        }
        
        @Test func whenProjectEditorIsDeleted() async throws {
            // given
            try await #require(projectModelRef.id.isExist == true)
            
            await projectModelRef.setCaptureHook {
                await projectModelRef.delete()
            }
            
            // when
            await projectModelRef.removeProject()
            
            // then
            let issue = try #require(await projectModelRef.issue)
            #expect(issue.reason == "projectModelIsDeleted")
        }
        
        @Test func removeProjectSource() async throws {
            // given
            let projectSource = projectModelRef.source
            
            await #expect(projectSource.isExist == true)
             
            // when
            await projectModelRef.removeProject()
            
            // then
            await #expect(projectSource.isExist == false)
        }
        @Test func removeProjectModelInProjectBoard() async throws {
            // given
            let projectBoardRef = try #require(await projectModelRef.config.parent.ref)
            try await #require(projectBoardRef.projects.values.contains(projectModelRef.id))
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await projectModelRef.startUpdating()
                    await projectModelRef.setCallback { continuation.resume() }
                    await #expect(projectModelRef.issue == nil)
                    
                    await projectModelRef.removeProject()
                }
            }
            
            // then
            await #expect(projectBoardRef.projects.values.contains(projectModelRef.id) == false)
            
        }
        
        @Test func deleteProjectModel() async throws {
            // given
            await projectModelRef.startUpdating()
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await projectModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await #expect(projectModelRef.issue == nil)
                    
                    await projectModelRef.removeProject()
                }
            }
            
            // then
            await #expect(projectModelRef.id.isExist == false)
        }
        
        @Test func deleteSystemModels() async throws {
            // given
            await projectModelRef.startUpdating()
            try await #require(projectModelRef.systems.isEmpty)
            
            await withCheckedContinuation { continuation in
                Task {
                    await projectModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await projectModelRef.createFirstSystem()
                }
            }
            
            try await #require(projectModelRef.systems.count == 1)
            
            let systemModel = try #require(await projectModelRef.systems.values.first)
            
            // when
            try await removeProjectWithContinuation(projectModelRef)
            
            // then
            await #expect(systemModel.isExist == false)
        }
        @Test func deleteRootObjectModel() async throws {
            // give
            let systemModelRef = try await createSystemModel(projectModelRef)
            let rootObjectModelRef = try await createRootObjectModel(systemModelRef)
            
            try await #require(rootObjectModelRef.id.isExist == true)
            
            // when
            try await removeProjectWithContinuation(projectModelRef)
            
            // then
            await #expect(rootObjectModelRef.id.isExist == false)
        }
        @Test(.disabled("구현 예정")) func deleteStateModels() async throws {
            Issue.record("미구현")
        }
        @Test(.disabled("구현 예정")) func deleteGetterModels() async throws {
            Issue.record("미구현")
        }
        @Test(.disabled("구현 예정")) func deleteSetterModels() async throws {
            Issue.record("미구현")
        }
        @Test(.disabled("구현 예정")) func deleteActionModels() async throws {
            Issue.record("미구현")
        }
        @Test(.disabled("구현 예정")) func deleteFlowModels() async throws {}
        
        @Test(.disabled("구현 예정")) func deleteWorkflowModels() async throws {}
        
        @Test(.disabled("구현 예정")) func deleteValueModels() async throws {}
    }
}


// MARK: Helphers
private func getProjectModel(_ budClientRef: BudClient) async throws -> ProjectModel {
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
    
    // ProjectEditor
    await #expect(projectBoardRef.projects.count == 1)
    return try #require(await projectBoardRef.projects.values.first?.ref)
}

private func removeProjectWithContinuation(_ projectModelRef: ProjectModel) async throws {
    await withCheckedContinuation { continuation in
        Task {
            await projectModelRef.setCallback {
                continuation.resume()
            }
            
            await #expect(projectModelRef.issue == nil)
            
            await projectModelRef.removeProject()
        }
    }
}

private func createSystemModel(_ projectModelRef: ProjectModel) async throws -> SystemModel {
    try await #require(projectModelRef.systems.isEmpty)
    
    await withCheckedContinuation { continuation in
        Task {
            await projectModelRef.setCallback {
                continuation.resume()
            }
            
            await projectModelRef.startUpdating()
            
            await projectModelRef.createFirstSystem()
        }
    }
    
    try await #require(projectModelRef.systems.count == 1)
    return try #require(await projectModelRef.systems.values.first?.ref)
}

private func createRootObjectModel(_ systemModelRef: SystemModel) async throws -> ObjectModel {
    try await #require(systemModelRef.root == nil)
    
    await withCheckedContinuation { continuation in
        Task {
            await systemModelRef.setCallback {
                continuation.resume()
            }
            
            await systemModelRef.startUpdating()
            
            await systemModelRef.createRootObject()
        }
    }
    
    try await #require(systemModelRef.objects.count == 1)
    return try #require(await systemModelRef.root?.ref)
}
