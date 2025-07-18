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
    struct StartUpdating {
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
            await systemModelRef.startUpdating {
                await systemModelRef.delete()
            }
            
            // then
            let issue = try #require(await systemModelRef.issue as? KnownIssue)
            #expect(issue.reason == "systemModelIsDeleted")
        }
        @Test func whenAlreadySubscribed() async throws {
            // given
            await systemModelRef.startUpdating()
            try await #require(systemModelRef.issue == nil)
            
            // when
            await systemModelRef.startUpdating()
            
            // then
            let issue = try #require(await systemModelRef.issue as? KnownIssue)
            #expect(issue.reason == "alreadySubscribed")
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
        @Test func updateNameByUpdater() async throws {
            // given
            let testName = "TEST_NAME"
            await MainActor.run {
                systemModelRef.nameInput = testName
            }
            
            try await #require(systemModelRef.name != testName)
            try await #require(systemModelRef.id.isExist == true)
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await systemModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await systemModelRef.pushName()
                }
            }
            
            await systemModelRef.setCallbackNil()
            
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
            // given
            try await #require(systemModelRef.id.isExist == true)
            
            // when
            await systemModelRef.addSystemRight {
                await systemModelRef.delete()
            }
            
            // then
            let issue = try #require(await systemModelRef.issue as? KnownIssue)
            #expect(issue.reason == "systemModelIsDeleted")
        }
        
        @Test func addRightSystemModelInProjectModel() async throws {
            // given
            let projectModelRef = try #require(await systemModelRef.config.parent.ref)
            
            let rightLocation = await systemModelRef.location.getRight()
            try await #require( projectModelRef.systemLocations.contains(rightLocation) == false)
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await projectModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await systemModelRef.addSystemRight()
                }
            }
            
            // then
            try await #require( projectModelRef.systemLocations.contains(rightLocation) == true)
        }
        @Test func whenRightSystemModelIsAlreadyExist() async throws {
            // given
            let rightLocation = await systemModelRef.location.getRight()
            let projectSourceRef = try #require(await systemModelRef
                .config.parent.ref?
                .source.ref as? ProjectSourceMock)
            
            try await #require(projectSourceRef.systems.count == 1)
            
            // when
            await systemModelRef.addSystemRight()
            await systemModelRef.addSystemRight()
            await systemModelRef.addSystemRight()
            await systemModelRef.addSystemRight()
            
            // then
            try await #require(projectSourceRef.isLocationExist(rightLocation) == true)
            
            await #expect(projectSourceRef.systems.count == 2)
        }
    }
    
    struct AddSystemLeft {
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
            await systemModelRef.addSystemLeft {
                await systemModelRef.delete()
            }
            
            // then
            let issue = try #require(await systemModelRef.issue as? KnownIssue)
            #expect(issue.reason == "systemModelIsDeleted")
        }
    
        @Test func addLeftSystemModelInProjectModel() async throws {
            // given
            let projectModelRef = try #require(await systemModelRef.config.parent.ref)
            
            let leftLocation = await systemModelRef.location.getLeft()
            try await #require(projectModelRef.systemLocations.contains(leftLocation) ==  false)
            
            // when
            await projectModelRef.startUpdating()
            await withCheckedContinuation { continuation in
                Task {
                    await projectModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await systemModelRef.addSystemLeft()
                }
            }
            await projectModelRef.setCallbackNil()
            
            // then
            try await #require(projectModelRef.systemLocations.contains(leftLocation))
        }
        @Test func whenLeftSystemModelIsAlreadyExist() async throws {
            // given
            let leftLocation = await systemModelRef.location.getLeft()
            let projectSourceRef = try #require(await systemModelRef
                .config.parent.ref?
                .source.ref as? ProjectSourceMock)
            
            try await #require(projectSourceRef.systems.count == 1)
            
            // when
            await systemModelRef.addSystemLeft()
            await systemModelRef.addSystemLeft()
            await systemModelRef.addSystemLeft()
            await systemModelRef.addSystemLeft()
            
            // then
            try await #require(projectSourceRef.isLocationExist(leftLocation) == true)
            
            await #expect(projectSourceRef.systems.count == 2)
        }
    }
    
    struct AddSystemTop {
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
            await systemModelRef.addSystemTop {
                await systemModelRef.delete()
            }
            
            // then
            let issue = try #require(await systemModelRef.issue as? KnownIssue)
            #expect(issue.reason == "systemModelIsDeleted")
        }
        
        @Test func addTopSystemModelInSystemBoard() async throws {
            // given
            let projectModelRef = try #require(await systemModelRef.config.parent.ref)
            
            let topLocation = await systemModelRef.location.getTop()
            try await #require(projectModelRef.systemLocations.contains( topLocation) == false)
            
            // when
            await projectModelRef.startUpdating()
            await withCheckedContinuation { continuation in
                Task {
                    await projectModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await systemModelRef.addSystemTop()
                }
            }
            await projectModelRef.setCallbackNil()
            
            // then
            try await #require( projectModelRef.systemLocations.contains(topLocation) == true)
        }
        @Test func whenTopSystemModelIsAlreadyExist() async throws {
            // given
            let topLocation = await systemModelRef.location.getTop()
            let projectSourceRef = try #require(await systemModelRef
                .config.parent.ref?
                .source.ref as? ProjectSourceMock)
            
            try await #require(projectSourceRef.systems.count == 1)
            
            // when
            await systemModelRef.addSystemTop()
            await systemModelRef.addSystemTop()
            await systemModelRef.addSystemTop()
            await systemModelRef.addSystemTop()
            
            // then
            try await #require(projectSourceRef.isLocationExist(topLocation) == true)
            
            await #expect(projectSourceRef.systems.count == 2)
        }
    }
    
    struct AddSystemBottom {
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
            await systemModelRef.addSystemBottom {
                await systemModelRef.delete()
            }
            
            // then
            let issue = try #require(await systemModelRef.issue as? KnownIssue)
            #expect(issue.reason == "systemModelIsDeleted")
        }
        
        @Test func addBottomSystemModelInProjectModel() async throws {
            // given
            let projectModelRef = try #require(await systemModelRef.config.parent.ref)
            
            let bottomLocation = await systemModelRef.location.getBotttom()
            try await #require(projectModelRef.systemLocations.contains(bottomLocation) == false)
            
            // when
            await projectModelRef.startUpdating()
            await withCheckedContinuation { continuation in
                Task {
                    await projectModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await systemModelRef.addSystemBottom()
                }
            }
            await projectModelRef.setCallbackNil()
            
            // then
            try #require(await projectModelRef.systemLocations.contains(bottomLocation) == true)
        }
        @Test func whenRightSystemModelIsAlreadyExist() async throws {
            // given
            let bottomLocation = await systemModelRef.location.getBotttom()
            let projectSourceRef = try #require(await systemModelRef
                .config.parent.ref?
                .source.ref as? ProjectSourceMock)
            
            try await #require(projectSourceRef.systems.count == 1)
            
            // when
            await systemModelRef.addSystemBottom()
            await systemModelRef.addSystemBottom()
            await systemModelRef.addSystemBottom()
            await systemModelRef.addSystemBottom()
            
            // then
            try await #require(projectSourceRef.isLocationExist(bottomLocation) == true)
            
            await #expect(projectSourceRef.systems.count == 2)
        }
    }
    
    struct RemoveSystem {
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
            await systemModelRef.removeSystem {
                await systemModelRef.delete()
            }
            
            // then
            let issue = try #require(await systemModelRef.issue as? KnownIssue)
            #expect(issue.reason == "systemModelIsDeleted")
        }
        
        @Test func removeSystemSource() async throws {
            // given
            let systemSource = systemModelRef.source
            try await #require(systemSource.isExist == true)
            
            // when
            await systemModelRef.removeSystem()
            
            // then
            await #expect(systemSource.isExist == false)
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
    return systemModelRef
}
