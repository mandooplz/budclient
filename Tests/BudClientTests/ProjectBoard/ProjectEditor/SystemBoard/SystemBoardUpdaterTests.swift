//
//  SystemBoardUpdaterTests.swift
//  BudClient
//
//  Created by 김민우 on 7/8/25.
//
import Foundation
import Testing
import Values
@testable import BudClient


// MARK: Tests
@Suite("SystemBoardUpdater")
struct SystemBoardUpdaterTests {
    struct Update {
        let budClientRef: BudClient
        let updaterRef: SystemBoardUpdater
        let systemBoardRef: SystemBoard
        init() async {
            self.budClientRef = await BudClient()
            self.updaterRef = await getSystemBoardUpdater(budClientRef)
            self.systemBoardRef = await updaterRef.config.parent.ref!
        }
        
        @Test func whenSystemBoardIsDeleted() async throws {
            // given
            try await #require(updaterRef.id.isExist == true)
            
            // when
            await updaterRef.update {
                await updaterRef.delete()
            }
            
            // then
            let issue = try #require(await updaterRef.issue as? KnownIssue)
            #expect(issue.reason == "updaterIsDeleted")
        }
        
        @Test func createSystemModel() async throws {
            // given
            try await #require(systemBoardRef.models.count == 0)
            
            let newSystemSource = SystemSourceID()
            let newSystem = SystemID()
            let addEvent = ProjectSourceEvent.added(newSystemSource, newSystem)
            
            await updaterRef.appendEvent(addEvent)
            
            // when
            await updaterRef.update()
            
            // then
            try await #require(systemBoardRef.models.count == 1)
            try await #require(updaterRef.queue.isEmpty)
            
            await #expect(systemBoardRef.models.first?.isExist == true)
        }
        @Test func whenAlreadyAdded() async throws {
            // given
            let newSystemSource = SystemSourceID()
            let newSystem = SystemID()
            let addEvent = ProjectSourceEvent.added(newSystemSource, newSystem)
            
            await updaterRef.appendEvent(addEvent)
            await updaterRef.update()
            
            // when
            await updaterRef.appendEvent(addEvent)
            await updaterRef.update()
            
            // then
            try await #require(updaterRef.queue.isEmpty)
            
            let issue = try #require(await updaterRef.issue as? KnownIssue)
            #expect(issue.reason == "alreadyAdded")
        }
        
        @Test func deleteSystemModel() async throws {
            // given
            let newSystemSource = SystemSourceID()
            let newSystem = SystemID()
            let addEvent = ProjectSourceEvent.added(newSystemSource, newSystem)
            
            await updaterRef.appendEvent(addEvent)
            await updaterRef.update()
            
            try await #require(systemBoardRef.models.count == 1)
            let systemModel = try #require(await systemBoardRef.models.first)
            try await #require(systemModel.isExist == true)
            
            // when
            let removeEvent = ProjectSourceEvent.removed(newSystem)
            
            await updaterRef.appendEvent(removeEvent)
            await updaterRef.update()
            
            // then
            try await #require(updaterRef.queue.isEmpty)
            
            await #expect(systemModel.isExist == false)
            await #expect(systemBoardRef.models.contains(systemModel) == false)
        }
        @Test func whenAlreadyRemoved() async throws {
            // given
            let someSystem = SystemID()
            let removeEvent = ProjectSourceEvent.removed(someSystem)
            
            await updaterRef.appendEvent(removeEvent)
            
            // when
            await updaterRef.update()
            
            // then
            try await #require(updaterRef.queue.isEmpty)
            
            let issue = try #require(await updaterRef.issue as? KnownIssue)
            #expect(issue.reason == "alreadyRemoved")
        }
        
        @Test func modifySystemModel() async throws {
            // given
            let newSystemSource = SystemSourceID()
            let newSystem = SystemID()
            let addEvent = ProjectSourceEvent.added(newSystemSource, newSystem)
            
            await updaterRef.appendEvent(addEvent)
            await updaterRef.update()
            
            let systemModelRef = try #require(await systemBoardRef.models.first?.ref)
            
            // when
            let testName = "TEST_Name"
            let testLocation = Location(x: 999, y: 999)
            let modifyEvent = SystemSourceDiff(target: newSystem,
                                               name: testName,
                                               location: testLocation).getEvent()
            
            await updaterRef.appendEvent(modifyEvent)
            await updaterRef.update()
            
            // then
            await #expect(systemModelRef.name == testName)
            await #expect(systemModelRef.location == testLocation)
        }
        @Test func modifySystemModelWhenAlreadyRemoved() async throws {
            // given
            let modifyEvent = SystemSourceDiff(target: .init(),
                                               name: "TEST_Name",
                                               location: .init(x: 1, y: 1)).getEvent()

            // when
            await updaterRef.appendEvent(modifyEvent)
            await updaterRef.update()
            
            // then
            let issue = try #require(await updaterRef.issue as? KnownIssue)
            #expect(issue.reason == "alreadyRemoved")
        }
    }
}


// MARK: Helpher
private func getSystemBoardUpdater(_ budClientRef: BudClient) async -> SystemBoardUpdater {
    let systemBoardRef = await createAndGetSystemBoard(budClientRef)
    
    await systemBoardRef.setUp()
    
    return await systemBoardRef.updater!.ref!
}
