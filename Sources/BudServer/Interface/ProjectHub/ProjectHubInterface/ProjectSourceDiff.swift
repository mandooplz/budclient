//
//  ProjectSourceDiff.swift
//  BudClient
//
//  Created by 김민우 on 7/15/25.
//
import Foundation
import Values


// MARK: Value
package struct ProjectSourceDiff: Sendable {
    package let id: any ProjectSourceIdentity
    package let target: ProjectID
    package let name: String
    
    package init(id: any ProjectSourceIdentity, target: ProjectID, name: String) {
        self.id = id
        self.target = target
        self.name = name
    }
}
