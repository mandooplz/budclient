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
        
        @Test func addRightSystemModelInSystemBoard() async throws {
            // given
            let systemBoardRef = try #require(await systemModelRef.config.parent.ref)
            
            let rightLocation = await systemModelRef.location.getRight()
            try await #require(systemBoardRef.models[rightLocation] == nil)
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await systemBoardRef.setCallback {
                        continuation.resume()
                    }
                    await systemBoardRef.subscribe()
                    
                    await systemModelRef.addSystemRight()
                }
            }
            
            // then
            let systemModel = try #require(await systemBoardRef.models[rightLocation])
            await #expect(systemModel.ref?.location == rightLocation)
        }
        @Test func whenRightSystemModelIsAlreadyExist() async throws {
            // given
            let rightLocation = await systemModelRef.location.getRight()
            let projectSourceRef = try #require(await systemModelRef
                .config.parent.ref?
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
    
        @Test func addLeftSystemModelInSystemBoard() async throws {
            // given
            let systemBoardRef = try #require(await systemModelRef.config.parent.ref)
            
            let leftLocation = await systemModelRef.location.getLeft()
            try await #require(systemBoardRef.models[leftLocation] == nil)
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await systemBoardRef.setCallback {
                        continuation.resume()
                    }
                    await systemBoardRef.subscribe()
                    
                    await systemModelRef.addSystemLeft()
                }
            }
            
            // then
            let systemModel = try #require(await systemBoardRef.models[leftLocation])
            await #expect(systemModel.ref?.location == leftLocation)
        }
        @Test func whenLeftSystemModelIsAlreadyExist() async throws {
            // given
            let leftLocation = await systemModelRef.location.getLeft()
            let projectSourceRef = try #require(await systemModelRef
                .config.parent.ref?
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
            let systemBoardRef = try #require(await systemModelRef.config.parent.ref)
            
            let topLocation = await systemModelRef.location.getTop()
            try await #require(systemBoardRef.models[topLocation] == nil)
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await systemBoardRef.setCallback {
                        continuation.resume()
                    }
                    await systemBoardRef.subscribe()
                    
                    await systemModelRef.addSystemTop()
                }
            }
            
            // then
            let systemModel = try #require(await systemBoardRef.models[topLocation])
            await #expect(systemModel.ref?.location == topLocation)
        }
        @Test func whenTopSystemModelIsAlreadyExist() async throws {
            // given
            let topLocation = await systemModelRef.location.getTop()
            let projectSourceRef = try #require(await systemModelRef
                .config.parent.ref?
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
        
        @Test func addBottomSystemModelInSystemBoard() async throws {
            // given
            let systemBoardRef = try #require(await systemModelRef.config.parent.ref)
            
            let bottomLocation = await systemModelRef.location.getBotttom()
            try await #require(systemBoardRef.models[bottomLocation] == nil)
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await systemBoardRef.setCallback {
                        continuation.resume()
                    }
                    await systemBoardRef.subscribe()
                    
                    await systemModelRef.addSystemBottom()
                }
            }
            
            // then
            let systemModel = try #require(await systemBoardRef.models[bottomLocation])
            await #expect(systemModel.ref?.location == bottomLocation)
        }
        @Test func whenRightSystemModelIsAlreadyExist() async throws {
            // given
            let bottomLocation = await systemModelRef.location.getBotttom()
            let projectSourceRef = try #require(await systemModelRef
                .config.parent.ref?
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
