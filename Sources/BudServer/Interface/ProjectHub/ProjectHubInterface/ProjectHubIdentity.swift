//
//  ProjectHubIdentity.swift
//  BudClient
//
//  Created by 김민우 on 7/15/25.
//
import Foundation
import Values


// MARK: Interface
package protocol ProjectHubIdentity: Sendable, Hashable {
    associatedtype Object: ProjectHubInterface where Object.ID == Self
    
    var isExist: Bool { get async }
    var ref: Object? { get async }
}
