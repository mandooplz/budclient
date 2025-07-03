//
//  ProjectTests.swift
//  BudClient
//
//  Created by 김민우 on 7/1/25.
//
import Foundation
import Testing
@testable import BudClient
@testable import BudServer


// MARK: Tests
@Suite("Project", .timeLimit(.minutes(1)))
struct ProjectTests {
    struct Push {
        let budClientRef: BudClient
        let projectRef: Project
        init() async {
            self.budClientRef = await BudClient()
            self.projectRef = await createAndGetProject(budClientRef)
        }
        
        @Test func whenProjectIsDeleted() async throws {
            // given
            try await #require(projectRef.id.isExist == true)
            
            // when
            await projectRef.push {
                await projectRef.delete()
            }
            
            // then
            let issue = try #require(await projectRef.issue)
            #expect(issue.reason == "projectIsDeleted")
        }
        @Test func whenNameIsNil() async throws {
            // given
            await MainActor.run {
                projectRef.name = nil
            }
            
            // when
            await projectRef.push()
            
            // then
            let issue = try #require(await projectRef.issue)
            #expect(issue.reason == "nameIsNil")
        }
        
        @Test func updateNameInProjectSource() async throws {
            // given
            let projectSourceLink = projectRef.sourceLink
            let testName = "TEST_PROJECT_NAME"
            
            try await #require(projectSourceLink.getName() != testName)
            
            await MainActor.run {
                projectRef.name = testName
            }
            
            // when
            await projectRef.push()
            
            // then
            await #expect(projectSourceLink.getName() == testName)
        }
        @Test func updateNameByCallback() async throws {
            // given
            let testName = "TEST_PROJECT_NAME"
            try await #require(projectRef.name != testName)
            
            // when
            // projectSourceLink.setNameTicket(다른시스템)
            // projectSourceLink.processNameTicket()
            
            // then
            await #expect(projectRef.name == testName)
            
        }
    }
    
    struct RemoveSource {
        let budClientRef: BudClient
        let projectRef: Project
        init() async {
            self.budClientRef = await BudClient()
            self.projectRef = await createAndGetProject(budClientRef)
        }
        
        @Test func whenProjectIsDeleted() async throws {
            // given
            try await #require(projectRef.id.isExist == true)
            
            // when
            await projectRef.removeSource {
                await projectRef.delete()
            }
            
            // then
            let issue = try #require(await projectRef.issue)
            #expect(issue.reason == "projectIsDeleted")
        }
        
        @Test func removeProject() async throws {
            // ProjectSource를 삭제하면
            // 누구에게 피드백이 가는가.
            // ProjectHub의 Notifier를 통해 전달된다. 
        }
    }
}


// MARK: Helphers
