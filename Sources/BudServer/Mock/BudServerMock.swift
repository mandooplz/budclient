//
//  BudServerMock.swift
//  BudClient
//
//  Created by 김민우 on 7/4/25.
//
import Foundation
import Values

@globalActor package final actor Server {
    package static let shared = Server()
    
    @discardableResult @Server
    package static func run<T>(resultType: T.Type = T.self,
                                                  body: @Server () async throws -> T)
    async rethrows -> T where T:Sendable {
        try await body()
    }
}


// MARK: Object
@Server
package final class BudServerMock: BudServerInterface {
    // MARK: core
    package init() {
        BudServerMockManager.register(self)
    }
    
    
    // MARK: state
    package nonisolated let id = ID()
    
    package let accountHub = AccountHubMock.shared.id
    
    private var projectHubRef: ProjectHubMock?
    package func getProjectHub(_ user: UserID) -> ProjectHubMock.ID {
        guard let projectHubRef else {
            let newProjectHubRef = ProjectHubMock(user: user)
            self.projectHubRef = newProjectHubRef
            return newProjectHubRef.id
        }
        
        return projectHubRef.id
    }
    
    
    // MARK: value
    @Server
    package struct ID: BudServerIdentity {
        let value = UUID()
        nonisolated init() { }
        
        package var isExist: Bool {
            BudServerMockManager.container[self] != nil
        }
        package var ref: BudServerMock? {
            BudServerMockManager.container[self]
        }
    }
}


// MARK: ObjectManager
@Server
fileprivate final class BudServerMockManager: Sendable {
    // MARK: state
    fileprivate static var container: [BudServerMock.ID: BudServerMock] = [:]
    fileprivate static func register(_ object: BudServerMock) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: BudServerMock.ID) {
        container[id] = nil
    }
}
