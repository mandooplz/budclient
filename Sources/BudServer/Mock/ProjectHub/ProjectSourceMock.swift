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
internal final class ProjectSourceMock: ServerObject {
    // MARK: core
    internal init(projectHubRef: ProjectHubMock,
                  userId: String) {
        self.id = ID(value: .init())
        self.projectHubRef = projectHubRef
        self.user = userId
        
        ProjectSourceMockManager.register(self)
    }
    internal func delete() {
        ProjectSourceMockManager.unregister(self.id)
    }
    
    
    
    // MARK: state
    internal nonisolated let id: ID
    internal nonisolated let projectHubRef: ProjectHubMock
    
    internal var name: String = "UnknownProject"
    internal var user: String
    
    
    // MARK: action
    
    
    // MARK: value
    @BudServer
    internal struct ID: ServerObjectID {
        let value: UUID
        typealias Object = ProjectSourceMock
        typealias Manager = ProjectSourceMockManager
    }
}


// MARK: Object Manager
@BudServer
internal final class ProjectSourceMockManager: ServerObjectManager {
    // MARK: state
    internal static var container: [ProjectSourceMock.ID: ProjectSourceMock] = [:]
}
