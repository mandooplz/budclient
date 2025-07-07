//
//  ProjectEvent.swift
//  BudClient
//
//  Created by 김민우 on 7/3/25.
//


// MARK: ProjectEvent
package enum ProjectSourceEvent: Sendable {
    case modified(Name)
//    case added(SystemSourceID, SystemID)
//    case removed(SystemID)
    
    package typealias Name = String
}
