//
//  ProjectTests.swift
//  BudClient
//
//  Created by 김민우 on 7/1/25.
//
import Foundation
import Testing
@testable import BudClient


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
        
        @Test func updateNameInProjectSource() async throws {
            // given
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
    }
}


// MARK: Helphers
