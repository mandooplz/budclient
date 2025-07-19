//
//  BudCache.swift
//  BudClient
//
//  Created by 김민우 on 7/11/25.
//
import Foundation
import Values
import BudServer
import FirebaseAuth

private let logger = BudLogger("BudCache")


// MARK: Object
@MainActor
package final class BudCache: BudCacheInterface {
    // MARK: core
    package init() {
        BudCacheManager.register(self)
    }
    
    
    // MARK: state
    package nonisolated let id = ID()
    
    package func getUser() -> UserID? {
        guard let value = Auth.auth().currentUser?.uid else {
            return nil
        }
        return UserID(value)
    }
    package func setUser(_ user: UserID?) {
        return
    }
    package func removeUser() {
        logger.start()
        
        do {
            try Auth.auth().signOut()
        } catch {
            logger.failure(error)
        }
    }
    
    
    // MARK: value
    @MainActor
    package struct ID: BudCacheIdentity {
        let value = "BudCache"
        nonisolated init() { }
        
        package var isExist: Bool {
            BudCacheManager.container[self] != nil
        }
        package var ref: BudCache? {
            BudCacheManager.container[self]
        }
    }
}


// MARK: ObjectManager
@MainActor
fileprivate final class BudCacheManager: Sendable {
    // MARK: state
    fileprivate static var container: [BudCache.ID: BudCache] = [:]
    fileprivate static func register(_ object: BudCache) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: BudCache.ID) {
        container[id] = nil
    }
}

