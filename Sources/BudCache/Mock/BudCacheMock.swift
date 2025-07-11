//
//  BudCacheMock.swift
//  BudClient
//
//  Created by 김민우 on 6/28/25.
//
import Foundation
import Values
import BudServer


// MARK: Object
@Server
package final class BudCacheMock: BudCacheInterface {
    // MARK: core
    package init() {
        BudCacheMockManager.register(self)
    }
    
    
    // MARK: state
    package nonisolated let id = ID()
    
    private var user: UserID?
    package func getUser() -> UserID? {
        self.user
    }
    package func setUser(_ user: UserID?) {
        self.user = user
    }
    package func removeUser() {
        self.user = nil
    }
    
    
    // MARK: value
    @Server
    package struct ID: BudCacheIdentity {
        let value = UUID()
        nonisolated init() { }
        
        package var isExist: Bool {
            BudCacheMockManager.container[self] != nil
        }
        package var ref: BudCacheMock? {
            BudCacheMockManager.container[self]
        }
    }
}


// MARK: ObjectManager
@Server
fileprivate final class BudCacheMockManager: Sendable {
    // MARK: state
    fileprivate static var container: [BudCacheMock.ID: BudCacheMock] = [:]
    fileprivate static func register(_ object: BudCacheMock) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: BudCacheMock.ID) {
        container[id] = nil
    }
}
