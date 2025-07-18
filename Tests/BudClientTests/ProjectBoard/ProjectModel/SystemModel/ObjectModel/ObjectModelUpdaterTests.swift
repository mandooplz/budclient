//
//  ObjectModelUpdaterTests.swift
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
@Suite("ObjectModel.Updater")
struct ObjectModelUpdaterTests {
    struct Update {
        let budClientRef: BudClient
        let objectModelRef: ObjectModel
        let updaterRef: ObjectModel.Updater
        init() async throws {
            self.budClientRef = await BudClient()
            self.objectModelRef = try await getObjectModel(budClientRef)
            self.updaterRef = objectModelRef.updaterRef
        }
        
        @Test func deleteObjectModel() async throws {
            // given
            let addedDiff = ObjectSourceDiff(
                id: ObjectSourceMock.ID(),
                target: .init(),
                name: "TEST_OBJECT",
                role: .node)
            
            let systemModelRef = await objectModelRef.config.parent.ref!
            let systemModelUpdaterRef = systemModelRef.updater
            
            await systemModelUpdaterRef.appendEvent(.objectAdded(addedDiff))
            
            try await #require(systemModelRef.objects.count == 1)
            let objectModel = try #require(await systemModelRef.objects.values.first)
            
            // when
            await updaterRef.appendEvent(.removed(addedDiff))
            await updaterRef.update()
            
            // then
            await #expect(objectModel.isExist == false)
        }
        @Test func removeObjectModelInSystemModel() async throws {
            // given
            let addedDiff = ObjectSourceDiff(
                id: ObjectSourceMock.ID(),
                target: .init(),
                name: "TEST_OBJECT",
                role: .node)
            
            let systemModelRef = await objectModelRef.config.parent.ref!
            let systemModelUpdaterRef = systemModelRef.updater
            
            await systemModelUpdaterRef.appendEvent(.objectAdded(addedDiff))
            
            try await #require(systemModelRef.objects.count == 1)
            let objectModel = try #require(await systemModelRef.objects.values.first)
            
            // when
            await updaterRef.appendEvent(.removed(addedDiff))
            await updaterRef.update()
            
            // then
            await #expect(systemModelRef.objects.values.contains(objectModel) == false)
        }
        @Test func whenAlreadyRemoved() async throws {
            // given
            let diff = ObjectSourceDiff(
                id: ObjectSourceMock.ID(),
                target: .init(),
                name: "TEST_OBJECT",
                role: .node)
            
            // when
            await updaterRef.appendEvent(.removed(diff))
            await updaterRef.update()
            
            // then
            let issue = try #require(await updaterRef.issue as? KnownIssue)
            #expect(issue.reason == "alreadyRemoved")
        }
        @Test func removeModifiedEventInQueue() async throws {
            // given
            try await #require(updaterRef.queue.isEmpty)
            
            let diff = ObjectSourceDiff(
                id: ObjectSourceMock.ID(),
                target: .init(),
                name: "TEST_OBJECT",
                role: .node)
            
            await updaterRef.appendEvent(.modified(diff))
            
            try await #require(updaterRef.queue.count == 1)
            
            // when
            await updaterRef.update()
            
            // then
            await #expect(updaterRef.queue.isEmpty)
        }
        
        @Test func modifyObjectModelName() async throws {
            // given
            let projectModelRef = await objectModelRef.config.parent.ref!
            let projectModelUpdaterRef = projectModelRef.updater
            
            let diff = ObjectSourceDiff(
                id: ObjectSourceMock.ID(),
                target: .init(),
                name: "TEST_OBJECT",
                role: .node)
            
            await projectModelUpdaterRef.appendEvent(.objectAdded(diff))
            await projectModelUpdaterRef.update()
            
            let objectModelRef = try #require(await projectModelRef.objects.values.first?.ref)
            await #expect(objectModelRef.name == "TEST_OBJECT")
            
            // when
            let newName = "NEW_NAME"
            let newDiff = ObjectSourceDiff(id: diff.id,
                                           target: diff.target,
                                           name: newName,
                                           role: .node)
            
            await updaterRef.appendEvent(.modified(newDiff))
            await updaterRef.update()
            
            // then
            try await #require(updaterRef.issue == nil)
            await #expect(objectModelRef.name == newName)
            
        }
        @Test func modifyRemovedObjectModel() async throws {
            // given
            let unknownDiff
            let systemSource = try #require(systemModelRef.source as? SystemSourceMock.ID)
            let systemSourceRef = try #require(await systemSource.ref)
            
            let diff = await ObjectSourceDiff(.init(name: "TEST",
                                                    parentRef: systemSourceRef))
            
            // when
            await MainActor.run {
                updaterRef.appendEvent(.modified(diff))
            }
            await updaterRef.update()
            
            // then
            let issue = try #require(await updaterRef.issue as? KnownIssue)
            #expect(issue.reason == "alreadyRemoved")
        }
        @Test func removeRemovedEventInQueue() async throws {
            // given
            try await #require(updaterRef.queue.isEmpty)
            
            let systemSource = try #require(systemModelRef.source as? SystemSourceMock.ID)
            let systemSourceRef = try #require(await systemSource.ref)
            
            let diff = await ObjectSourceDiff(.init(name: "TEST",
                                                    parentRef: systemSourceRef))
            
            await MainActor.run {
                updaterRef.appendEvent(.removed(diff))
            }
            
            try await #require(updaterRef.queue.count == 1)
            
            // when
            await updaterRef.update()
            
            // then
            await #expect(updaterRef.queue.isEmpty)
        }
    }
}


// MARK: Helphers
private func getObjectModel(_ budClientRef: BudClient) async throws -> ObjectModel {
    fatalError()
}
