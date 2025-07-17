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
    
    // accountHub가 과연 필요한가.
    var accountHub: AccountHubID { get async }
    
    func getProjectHub(_ user: UserID) async -> ProjectHubID
}


package protocol BudServerIdentity: Sendable, Hashable {
    associatedtype Object: BudServerInterface where Object.ID == Self
    
    var isExist: Bool { get async }
    var ref: Object? { get async }
}

