//
//  ProjectID.swift
//  BudClient
//
//  Created by 김민우 on 7/15/25.
//
import Foundation
import Values


// MARK: Value
package struct ProjectID: Identity {
    package let value: UUID
    
    package init(value: UUID = UUID()) {
        self.value = value
    }
    
    package func encode() -> [String: Any] {
        return ["value": value]
    }
}
