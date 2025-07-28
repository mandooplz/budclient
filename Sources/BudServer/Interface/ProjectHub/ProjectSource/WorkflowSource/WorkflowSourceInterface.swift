//
//  WorkflowSourceInterface.swift
//  BudClient
//
//  Created by 김민우 on 7/28/25.
//
import Foundation
import Values


// MARK: Interface
package protocol WorkflowSourceInterface: Sendable {
    associatedtype ID: WorkflowSourceIdentity where ID.Object == Self
}


package protocol WorkflowSourceIdentity: Sendable, Hashable {
    associatedtype Object: WorkflowSourceInterface where Object.ID == Self
    
    var isExist: Bool { get async }
    var ref: Object? { get async }
}


// MARK: Values
package struct WorkflowSourceDiff: Sendable {
    package let id: any WorkflowSourceIdentity
    package let target: WorkflowID
    
    package let createdAt: Date
    package let updatedAt: Date
    package let order: Int
}
