//
//  BudServerInterface.swift
//  BudClient
//
//  Created by 김민우 on 7/10/25.
//
import Foundation
import Values


// MARK: Interface
package protocol BudServerInterface: Sendable {
    associatedtype ID: BudServerIdentity where ID.Object == Self
    associatedtype AccountHubID: AccountHubIdentity
    associatedtype ProjectHubID: ProjectHubIdentity
    
    // MARK: state
    nonisolated var id: ID { get }
    
    var accountHub: AccountHubID { get async }
    var projectHub: ProjectHubID { get async }
}


package protocol BudServerIdentity: Sendable, Hashable {
    associatedtype Object: BudServerInterface where Object.ID == Self
    
    var isExist: Bool { get async }
    var ref: Object? { get async }
}

