//
//  ProjectSourceValues.swift
//  BudClient
//
//  Created by 김민우 on 7/17/25.
//
import Foundation
import Values


// MARK: ProjectSourceEvent
public enum ProjectSourceEvent: Sendable {
    case modified(ProjectSourceDiff)
    case removed(ProjectSourceDiff)
    
    case added(SystemSourceDiff)
}


// MARK: ProjectSourceDiff
public struct ProjectSourceDiff: Sendable {
    package let id: any ProjectSourceIdentity
    package let target: ProjectID
    package let name: String
    
    package init(id: any ProjectSourceIdentity, target: ProjectID, name: String) {
        self.id = id
        self.target = target
        self.name = name
    }
    
    package func changeName(_ value: String) -> Self {
        .init(id: self.id, target: self.target, name: value)
    }
}
