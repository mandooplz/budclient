//
//  SystemBoardTests.swift
//  BudClient
//
//  Created by 김민우 on 7/7/25.
//
import Foundation
import Testing
import Values
@testable import BudClient
@testable import BudServer


// MARK: Tests
@Suite("SystemBoard", .timeLimit(.minutes(1)))
struct SystemBoardTests {
    struct Subscribe {
        let budClientRef: BudClient
        let systemBoardRef: SystemBoard
        init() async {
            self.budClientRef = await BudClient()
            self.systemBoardRef = await getSystemBoard(budClientRef)
        }
        
        @Test func whenSystemBoardIsDeleted() async throws {
            // given
            try await #require(systemBoardRef.id.isExist == true)
            
            // when
            await systemBoardRef.subscribe {
                await systemBoardRef.delete()
            }
            
            // then
            let issue = try #require(await systemBoardRef.issue)
            #expect(issue.reason == "systemBoardIsDeleted")
        }
        
        @Test func setHandlerInProjectSource() async throws {
            // given
            let projectEditorRef = try #require(await systemBoardRef.config.parent.ref)
            let projectSourceLink = projectEditorRef.sourceLink
            
            let me = await ObjectID(systemBoardRef.id.value)
            
            try await #require(projectSourceLink.hasHandler(object: me) == false)
            
            // when
            await systemBoardRef.subscribe()
            
            // then
            await #expect(projectSourceLink.hasHandler(object: me) == true)
        }
    }
    
    struct Unsubscribe {
        let budClientRef: BudClient
        let systemBoardRef: SystemBoard
        init() async {
            self.budClientRef = await BudClient()
            self.systemBoardRef = await getSystemBoard(budClientRef)
        }
        
        @Test func removeHandlerInProjectSource() async throws {
            // given
            let projectEditorRef = try #require(await systemBoardRef.config.parent.ref)
            let projectSourceLink = projectEditorRef.sourceLink
            
            let me = await ObjectID(systemBoardRef.id.value)
            
            await systemBoardRef.subscribe()
            
            try await #require(projectSourceLink.hasHandler(object: me) == true)
            
            // when
            await systemBoardRef.unsubscribe()
            
            // then
            await #expect(projectSourceLink.hasHandler(object: me) == false)
        }
    }
    
    struct CreateFirstSystem {
        let budClientRef: BudClient
        let systemBoardRef: SystemBoard
        init() async {
            self.budClientRef = await BudClient()
            self.systemBoardRef = await getSystemBoard(budClientRef)
        }
        
        @Test func whenSystemBoardIsDeleted() async throws {
            // given
            try await #require(systemBoardRef.id.isExist == true)
            
            // when
            await systemBoardRef.createFirstSystem {
                await systemBoardRef.delete()
            }
            
            // then
            let issue = try #require(await systemBoardRef.issue as? KnownIssue)
            #expect(issue.reason == "systemBoardIsDeleted")
        }
        @Test func whenSystemAlreadyExist() async throws {
            // given
            await withCheckedContinuation { con in
                Task {
                    await systemBoardRef.setCallback {
                        con.resume()
                    }
                    
                    await systemBoardRef.subscribe()
                    await systemBoardRef.createFirstSystem()
                }
            }
            
            try await #require(systemBoardRef.models.isEmpty == false)
            try await #require(systemBoardRef.issue == nil)
            
            // when
            await systemBoardRef.createFirstSystem()
            
            // then
            let issue = try #require(await systemBoardRef.issue as? KnownIssue)
            #expect(issue.reason == "systemAlreadyExist")
        }
        
        @Test func createSystemModel() async throws {
            // given
            try await #require(systemBoardRef.models.isEmpty == true)
            
            await systemBoardRef.unsubscribe()
            
            // when
            await withCheckedContinuation { con in
                Task {
                    await systemBoardRef.setCallback {
                        con.resume()
                    }
                    await systemBoardRef.subscribe()
                    
                    await systemBoardRef.createFirstSystem()
                }
            }
            
            // then
            try await #require(systemBoardRef.models.count == 1)
            
            let systemModel = try #require(await systemBoardRef.models.values.first)
            await #expect(systemModel.isExist == true)
        }
        @Test func createSystemSource() async throws {
            // given
            let projectEditorRef = try #require(await systemBoardRef.config.parent.ref)
            let projectSourceLink = projectEditorRef.sourceLink
            
            try await #require(projectSourceLink.getSystemSources().isEmpty == true)
            
            // when
            await systemBoardRef.createFirstSystem()
            
            // then
            await #expect(projectSourceLink.getSystemSources().count == 1)
        }
    }
}



