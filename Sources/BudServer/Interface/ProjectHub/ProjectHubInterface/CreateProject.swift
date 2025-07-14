//
//  CreateProject.swift
//  BudClient
//
//  Created by 김민우 on 7/15/25.
//
import Foundation
import Values


// MARK: Value
package struct CreateProject: Sendable, Hashable {
    package let name: String
    package let creator: UserID
    
    package init(name: String, creator: UserID) {
        self.name = name
        self.creator = creator
    }
}
