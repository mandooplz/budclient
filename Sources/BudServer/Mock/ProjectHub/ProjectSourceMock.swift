//
//  ProjectSourceMock.swift
//  BudClient
//
//  Created by 김민우 on 6/30/25.
//
import Foundation
import Tools


// MARK: Object
@Server
final class ProjectSourceMock: ServerObject {
    // MARK: core
    init(projectHubRef: ProjectHubMock,
                  userId: String) {
        self.id = ID(value: .init())
        self.projectHubRef = projectHubRef
        self.user = userId
        
        ProjectSourceMockManager.register(self)
    }
    func delete() {
        ProjectSourceMockManager.unregister(self.id)
    }
    
    
    
    // MARK: state
    nonisolated let id: ID
    nonisolated let projectHubRef: ProjectHubMock
    
    var name: String = "UnknownProject"
    var user: String
    
    
    // MARK: action
    
    
    // MARK: value
    @Server
    struct ID: ServerObjectID {
        let value: UUID
        typealias Object = ProjectSourceMock
        typealias Manager = ProjectSourceMockManager
    }
}


// MARK: Object Manager
@Server
final class ProjectSourceMockManager: ServerObjectManager {
    // MARK: state
    static var container: [ProjectSourceMock.ID: ProjectSourceMock] = [:]
}
