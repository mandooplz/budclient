//
//  BudServer.swift
//  BudClient
//
//  Created by 김민우 on 7/10/25.
//
import Foundation
import Values
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore


// MARK: Object
@MainActor
package final class BudServer: BudServerInterface {
    // MARK: core
    package init(plistPath: String) async throws(Error) {
        if FirebaseApp.app() != nil { return }
        
        guard let options = FirebaseOptions(contentsOfFile: plistPath) else {
            throw Error.plistPathIsWrong
        }
        
        FirebaseApp.configure(options: options)
        
        BudServerManager.register(self)
    }
    
    
    // MARK: state
    nonisolated package let id = ID()
    
    package var accountHub = AccountHub.shared.id
    
    private var projectHubRef: ProjectHub?
    package func getProjectHub(_ user: UserID) -> ProjectHub.ID {
        guard let projectHubRef else {
            let newProjectHubRef = ProjectHub(user: user)
            self.projectHubRef = newProjectHubRef
            return newProjectHubRef.id
        }
        
        return projectHubRef.id
    }
    
    
    // MARK: value
    @MainActor
    package struct ID: BudServerIdentity {
        let value: String = "BudServer"
        nonisolated init() { }
        
        package var isExist: Bool {
            BudServerManager.container[self] != nil
        }
        package var ref: BudServer? {
            BudServerManager.container[self]
        }
    }
    package enum Error: String, Swift.Error {
        case plistPathIsWrong
    }
}


// MARK: ObjectManager
@MainActor
fileprivate final class BudServerManager: Sendable {
    fileprivate static var container: [BudServer.ID: BudServer] = [:]
    fileprivate static func register(_ object: BudServer) {
        container[object.id] = object
    }
}
