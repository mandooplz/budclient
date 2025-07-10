//
//  ProjectSourceLink.swift
//  BudClient
//
//  Created by 김민우 on 6/26/25.
//
import Foundation
import Values
import BudServerMock
import BudServerLocal


// MARK: Link
package struct ProjectSourceLink: Sendable, Hashable {
    // MARK: core
    private let mode: SystemMode
    package let object: ProjectSourceID
    private typealias TestManager = ProjectSourceMockManager
    private typealias RealManager = ProjectSourceManager
    package init(mode: SystemMode, object: ProjectSourceID) {
        self.mode = mode
        self.object = object
    }
    
    
    // MARK: state
    @Server func getSystemSources() async -> Set<SystemSourceID> {
        switch mode {
        case .test:
            return TestManager.get(object)!.systems
        case .real:
            fatalError()
        }
    }
    
    @Server package func setName(_ value: String) async {
        switch mode {
        case .test:
            TestManager.get(object)?.name = value
        case .real:
            await RealManager.get(object)?.setName(value)
        }
    }
    
    @Server package func hasHandler(requester: ObjectID) async -> Bool {
        switch mode {
        case .test:
            return TestManager.get(object)?.eventHandlers[requester] != nil
        case .real:
            return await MainActor.run {
                return RealManager.get(object)?.hasHandler(requester: requester) ?? false
            }
        }
    }
    @Server package func setHandler(requester: ObjectID, handler: Handler<ProjectSourceEvent>) async {
        switch mode {
        case .test:
            TestManager.get(object)?.eventHandlers[requester] = handler
        case .real:
            await MainActor.run {
                RealManager.get(object)?.setHandler(requester: requester, handler: handler)
            }
        }
    }
    @Server package func removeHandler(requester: ObjectID) async {
        switch mode {
        case .test:
            TestManager.get(object)?.eventHandlers[requester] = nil
            
        case .real:
            await MainActor.run {
                RealManager.get(object)?.removeHandler(requester: requester)
            }
        }
    }
    
    package func isExist() async -> Bool {
        switch mode {
        case .test:
            return await TestManager.isExist(object)
        case .real:
            return await RealManager.isExist(object)
        }
    }
    
    
    
    // MARK: action
    @Server package func remove() async {
        switch mode {
        case .test:
            TestManager.get(object)?.remove()
        case .real:
            await MainActor.run {
                RealManager.get(object)?.remove()
            }
        }
    }
    @Server package func createFirstSystem() async throws {
        switch mode {
        case .test:
            TestManager.get(object)?.createFirstSystem()
        case .real:
            try await RealManager.get(object)?.createFirstSystem()
        }
    }
}
