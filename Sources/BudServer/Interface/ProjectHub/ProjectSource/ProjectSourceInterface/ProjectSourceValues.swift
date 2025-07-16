//
//  ProjectSourceValues.swift
//  BudClient
//
//  Created by 김민우 on 7/17/25.
//
import Foundation
import Values


// ProjectSourceEvent를 더이상 받지 않겠다.
// modified와 removed에 대한 수신을 중단하겠다.
// 
// MARK: ProjectSourceEvent
package enum ProjectSourceEvent: Sendable {
    case modified(ProjectSourceDiff)
    case removed(ProjectSourceDiff)
    
    case added(SystemSourceDiff)
}


// MARK: ProjectSourceDiff
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
