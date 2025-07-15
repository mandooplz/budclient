//
//  DB.swift
//  BudClient
//
//  Created by 김민우 on 7/7/25.
//


// MARK: DB
enum DB: Sendable {
    static let projectSources = "ProjectSources"
    static let systemSources = "SystemSources"
    
    static let rootStateSources = "RootStateSources"
    static let rootActionSources = "RootActionSources"
    
    static let objectSources = "ObjectSources"
    static let objectStateSources = "ObjectStateSources"
    static let objectActionSources = "ObjectActionSources"
    
    static let valueCardSources = "ValueCardSources"
    static let objectCardSources = "ObjectCardSources"
}

