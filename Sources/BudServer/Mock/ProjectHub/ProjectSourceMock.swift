//
//  ProjectSourceMock.swift
//  BudClient
//
//  Created by 김민우 on 6/30/25.
//
import Foundation
import Tools


// MARK: Object
@BudServer
internal final class ProjectSourceMock: Sendable {
    // MARK: core
    internal init(projectHubRef: ProjectHubMock,
                  userId: String) {
        self.id = ID(value: .init())
        self.projectHubRef = projectHubRef
        self.userId = userId
        
        ProjectSourceMockManager.register(self)
    }
    internal func delete() {
        ProjectSourceMockManager.unregister(self.id)
    }
    
    
    
    // MARK: state
    internal nonisolated let id: ID
    internal nonisolated let projectHubRef: ProjectHubMock
    
    internal var name: String = "UnknownProject"
    internal var userId: String
    
    
    // MARK: action
    
    
    // MARK: value
    @BudServer
    internal struct ID: Sendable, Hashable {
        let value: UUID
        
        var isExist: Bool {
            ProjectSourceMockManager.container[self] != nil
        }
        var ref: ProjectSourceMock? {
            ProjectSourceMockManager.container[self]
        }
    }
}


// MARK: Object Manager
@BudServer
fileprivate final class ProjectSourceMockManager: Sendable {
    // MARK: state
    fileprivate static var container: [ProjectSourceMock.ID: ProjectSourceMock] = [:]
    fileprivate static func register(_ object: ProjectSourceMock) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: ProjectSourceMock.ID) {
        container[id] = nil
    }
}
