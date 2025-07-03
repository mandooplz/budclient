//
//  ProjectEvent.swift
//  BudClient
//
//  Created by 김민우 on 7/3/25.
//


package enum ProjectEvent: Sendable {
    case modified(Name)
    
    package typealias Name = String
}
