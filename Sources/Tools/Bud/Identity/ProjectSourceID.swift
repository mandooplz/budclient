//
//  ProjectSourceID.swift
//  BudClient
//
//  Created by 김민우 on 7/3/25.
//
import Foundation


// MARK: ProjectSourceID
package struct ProjectSourceID: Identity {
    package let value: String
    
    package init(_ value: String) {
        self.value = value
    }
    
    package init(uuid: UUID = UUID()) {
        self.value = uuid.uuidString
    }
}
