//
//  RootActionSourceInterface.swift
//  BudClient
//
//  Created by 김민우 on 7/15/25.
//
import Foundation
import Values


// MARK: Interface
package protocol RootActionSourceInterface: Sendable {
    associatedtype ID: RootActionSourceIdentity where ID.Object == Self
    
    nonisolated var id: ID { get }
}


package protocol RootActionSourceIdentity: Sendable, Hashable {
    associatedtype Object: RootActionSourceInterface where Object.ID == Self
    
    var isExist: Bool { get async }
    var ref: Object? { get async }
}
