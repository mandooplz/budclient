//
//  RootStateSourceInterface.swift
//  BudClient
//
//  Created by 김민우 on 7/15/25.
//
import Foundation
import Values


// MARK: Interface
package protocol RootStateSourceInterface: Sendable {
    associatedtype ID: RootStateSourceIdentity where ID.Object == Self
    
    nonisolated var id: ID { get }
}


package protocol RootStateSourceIdentity: Sendable, Hashable {
    associatedtype Object: RootStateSourceInterface where Object.ID == Self
    
    var isExist: Bool { get async }
    var ref: Object? { get async }
}

