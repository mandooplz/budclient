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


// MARK: Tests
@Suite("SystemModel", .timeLimit(.minutes(1)))
struct SystemModelTests {
    struct Subscribe {
        let budClientRef: BudClient
        let systemModelRef: SystemModel
        init() async {
            self.budClientRef = await BudClient()
            self.systemModelRef = await getSystemModel(budClientRef)
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
    }
    
    struct Unsubscribe {
        let budClientRef: BudClient
        let systemModelRef: SystemModel
        init() async {
            self.budClientRef = await BudClient()
            self.systemModelRef = await getSystemModel(budClientRef)
        }
    }
    
    struct PushName {
        let budClientRef: BudClient
        let systemModelRef: SystemModel
        init() async {
            self.budClientRef = await BudClient()
            self.systemModelRef = await getSystemModel(budClientRef)
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
    }
    
    struct Remove {
        let budClientRef: BudClient
        let systemModelRef: SystemModel
        init() async {
            self.budClientRef = await BudClient()
            self.systemModelRef = await getSystemModel(budClientRef)
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
