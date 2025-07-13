//
//  BudCacheInterface.swift
//  BudClient
//
//  Created by 김민우 on 7/11/25.
//
import Foundation
import Values
import FirebaseAuth
import BudServer


// MARK: Interface
package protocol BudCacheInterface: Sendable {
    associatedtype ID: BudCacheIdentity where ID.Object == Self
    
    func getUser() async -> UserID?
    func setUser(_ user: UserID?) async
    func removeUser() async
}

package protocol BudCacheIdentity: Sendable, Hashable {
    associatedtype Object: BudCacheInterface where Object.ID == Self
    
    var isExist: Bool { get async }
    var ref: Object? { get async }
}

