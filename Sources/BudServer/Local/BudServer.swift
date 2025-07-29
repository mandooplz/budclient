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
import FirebaseFunctions
import FirebaseStorage


// MARK: Object
@MainActor
package final class BudServer: BudServerInterface {
    // MARK: core
    package init(plistPath: String, useEmulators: Bool) async throws(Error) {
        if FirebaseApp.app() != nil { return }
        
        guard let options = FirebaseOptions(contentsOfFile: plistPath) else {
            throw Error.plistPathIsWrong
        }
        
        FirebaseApp.configure(options: options)
        if useEmulators { setUpEmulators() }
        
        BudServerManager.register(self)
    }
    private func setUpEmulators() {
        // iOS 시뮬레이터에서의 localhost
        let host = "127.0.0.1"
        
        // Authentication 에뮬레이터 설정
        Auth.auth().useEmulator(withHost: host, port: 9099)
        
        // Firestore 에뮬레이터 설정
        let settings = Firestore.firestore().settings
        settings.host = "\(host):8080" // 기본값: 8080
        settings.isSSLEnabled = false  // 로컬 에뮬레이터는 SSL을 사용하지 않으므로 false로 설정
        Firestore.firestore().settings = settings
        

        // Functions 에뮬레이터 설정
        Functions.functions().useEmulator(withHost: host, port: 5001)
        
        // Storage 에뮬레이터 설정
        Storage.storage().useEmulator(withHost: host, port: 9199)
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
