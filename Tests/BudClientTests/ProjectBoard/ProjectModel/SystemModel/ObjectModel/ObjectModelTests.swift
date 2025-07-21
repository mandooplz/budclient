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
@Suite("ObjectModel", .timeLimit(.minutes(1)))
struct ObjectModelTests {
    struct StartUpdating {
        let budClientRef: BudClient
        let objectModelRef: ObjectModel
        let objectSourceRef: ObjectSourceMock
        init() async throws {
            self.budClientRef = await BudClient()
            self.objectModelRef = try await getRootObjectModel(budClientRef)
            self.objectSourceRef = await objectModelRef.source.ref as! ObjectSourceMock
        }
        
        @Test func whenObjectModelIsDeleted() async throws {
            // given
            try await #require(objectModelRef.id.isExist == true)
            
            await objectModelRef.setCaptureHook {
                await objectModelRef.delete()
            }
            
            // when
            await objectModelRef.startUpdating()
            
            // then
            let issue = try #require(await objectModelRef.issue as? KnownIssue)
            #expect(issue.reason == "objectModelIsDeleted")
        }
        
        @Test func setIsUpdatingTrue() async throws {
            // given
            try await #require(objectModelRef.isUpdating == false)
            
            // when
            await objectModelRef.startUpdating()
            
            // then
            try await #require(objectModelRef.issue == nil)
            
            await #expect(objectModelRef.isUpdating == true)
        }
        @Test func whenAlreadyUpdating() async throws {
            // given
            await objectModelRef.startUpdating()
            
            try await #require(objectModelRef.issue == nil)
            
            // when
            await objectModelRef.startUpdating()
            
            // then
            let issue = try #require(await objectModelRef.issue as? KnownIssue)
            #expect(issue.reason == "alreadyUpdating")
        }
        
        @Test func receiveInitialAdded_StateAdded() async throws {
            // given
            try await #require(objectSourceRef.states.isEmpty)
            await objectSourceRef.appendNewState()
            try await #require(objectSourceRef.states.count == 1)
            
            try await #require(objectModelRef.states.isEmpty)
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await objectModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await objectModelRef.startUpdating()
                }
            }
            
            // then
            await #expect(objectModelRef.states.count == 1)
        }
        @Test func receiveInitialEvent_ActionAdded() async throws {
            // given
            try await #require(objectSourceRef.actions.isEmpty)
            await objectSourceRef.appendNewAction()
            try await #require(objectSourceRef.actions.count == 1)
            
            try await #require(objectModelRef.actions.isEmpty)
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await objectModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await objectModelRef.startUpdating()
                }
            }
            
            // then
            await #expect(objectModelRef.actions.count == 1)
        }
    }
    
    struct PushName {
        let budClientRef: BudClient
        let objectModelRef: ObjectModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.objectModelRef = try await getRootObjectModel(budClientRef)
        }
        
        @Test func whenObjectModelIsDeleted() async throws {
            // given
            try await #require(objectModelRef.id.isExist == true)
            
            await objectModelRef.setCaptureHook {
                await objectModelRef.delete()
            }
            
            // when
            await objectModelRef.pushName()
            
            // then
            let issue = try #require(await objectModelRef.issue as? KnownIssue)
            #expect(issue.reason == "objectModelIsDeleted")
        }
        
        @Test func whenNameInputIsEmpty() async throws {
            // given
            await MainActor.run {
                objectModelRef.nameInput = ""
            }
            
            // when
            await objectModelRef.pushName()
            
            // then
            let issue = try #require(await objectModelRef.issue as? KnownIssue)
            #expect(issue.reason == "nameCannotBeEmpty")
        }
        @Test func whenNameInputIsSameWithName() async throws {
            // given
            await MainActor.run {
                let testName = "TEST_NAME"
                objectModelRef.nameInput = testName
                objectModelRef.name = testName
            }
            
            // when
            await objectModelRef.pushName()
            
            // then
            let issue = try #require(await objectModelRef.issue as? KnownIssue)
            #expect(issue.reason == "newNameIsSameAsCurrent")
        }
        
        @Test func updateNameByUpdater() async throws {
            // given
            let oldName = "OLD_NAME"
            let newName = "NEW_NAME"
            
            await MainActor.run {
                objectModelRef.name = oldName
                objectModelRef.nameInput = newName
            }
            
            try await #require(objectModelRef.isUpdating == false)
            await objectModelRef.startUpdating()
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await objectModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await objectModelRef.pushName()
                }
            }
            
            // then
            await #expect(objectModelRef.name != oldName)
            await #expect(objectModelRef.name == newName)
        }
    }
    
    struct createChildObject {
        let budClientRef: BudClient
        let objectModelRef: ObjectModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.objectModelRef = try await getRootObjectModel(budClientRef)
        }
        
        @Test func whenObjectModelIsDeleted() async throws {
            // given
            try await #require(objectModelRef.id.isExist == true)
            
            await objectModelRef.setCaptureHook {
                await objectModelRef.delete()
            }
            
            // when
            await objectModelRef.createChildObject()
            
            // then
            let issue = try #require(await objectModelRef.issue as? KnownIssue)
            #expect(issue.reason == "objectModelIsDeleted")
        }
        
        @Test func appendObjectModel_SystemModel() async throws {
            Issue.record("구현 필요")
            // given
            let systemModelRef = try #require(await objectModelRef.config.parent.ref)
            
            let count = await systemModelRef.objects.count
            
            try await #require(systemModelRef.isUpdating == true)
            try #require(objectModelRef.role == .root)
            
            // when
            await withCheckedContinuation { continuation in
                Task {
                    await systemModelRef.setCallback {
                        continuation.resume()
                    }
                    
                    await objectModelRef.createChildObject()
                }
            }
            
            // then
            await #expect(systemModelRef.objects.count == count+1)
        }
    }
    
    struct AppendNewState {
        let budClientRef: BudClient
        let objectModelRef: ObjectModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.objectModelRef = try await getRootObjectModel(budClientRef)
        }
        
        @Test func whenObjectModelIsDeleted() async throws {
            // given
            try await #require(objectModelRef.id.isExist == true)
            
            await objectModelRef.setCaptureHook {
                await objectModelRef.delete()
            }
            
            // when
            await objectModelRef.appendNewState()
            
            // then
            let issue = try #require(await objectModelRef.issue as? KnownIssue)
            #expect(issue.reason == "objectModelIsDeleted")
        }
    }
    struct AppendNewAction {
        let budClientRef: BudClient
        let objectModelRef: ObjectModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.objectModelRef = try await getRootObjectModel(budClientRef)
        }
        
        @Test func whenObjectModelIsDeleted() async throws {
            // given
            try await #require(objectModelRef.id.isExist == true)
            
            await objectModelRef.setCaptureHook {
                await objectModelRef.delete()
            }
            
            // when
            await objectModelRef.appendNewAction()
            
            // then
            let issue = try #require(await objectModelRef.issue as? KnownIssue)
            #expect(issue.reason == "objectModelIsDeleted")
        }
    }
    
    struct RemoveObject {
        let budClientRef: BudClient
        let objectModelRef: ObjectModel
        init() async throws {
            self.budClientRef = await BudClient()
            self.objectModelRef = try await getRootObjectModel(budClientRef)
        }
        
        @Test func whenObjectModelIsDeleted() async throws {
            // given
            try await #require(objectModelRef.id.isExist == true)
            
            await objectModelRef.setCaptureHook {
                await objectModelRef.delete()
            }
            
            // when
            await objectModelRef.removeObject()
            
            // then
            let issue = try #require(await objectModelRef.issue as? KnownIssue)
            #expect(issue.reason == "objectModelIsDeleted")
        }
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
    
    await #expect(projectBoardRef.projects.count == 1)

    // ProjectModel.createFirstSystem
    let projectModelRef = try #require(await projectBoardRef.projects.values.first?.ref)
    
    await projectModelRef.startUpdating()
    await withCheckedContinuation { continuation in
        Task {
            await projectModelRef.setCallback {
                continuation.resume()
            }
            
            await projectModelRef.createFirstSystem()
        }
    }
    
    
    // SystemModel
    let systemModelRef = try #require(await projectModelRef.systems.values.first?.ref)
    await systemModelRef.startUpdating()
    
    await withCheckedContinuation { continuation in
        Task {
            await systemModelRef.setCallback {
                continuation.resume()
            }
            
            await systemModelRef.createRootObject()
        }
    }
    
    let rootObjectModelRef = try #require(await systemModelRef.root?.ref)
    return rootObjectModelRef
}
