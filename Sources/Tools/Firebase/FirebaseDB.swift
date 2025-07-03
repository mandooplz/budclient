//
//  FirebaseDB.swift
//  BudClient
//
//  Created by 김민우 on 7/3/25.
//


// MARK: FirebaseDB
package struct DB: Sendable {
    package static let projects = Projects()
    
    package struct Projects: Sendable {
        func callAsFunction() -> String {
            return "projects"
        }
        
    }
}
