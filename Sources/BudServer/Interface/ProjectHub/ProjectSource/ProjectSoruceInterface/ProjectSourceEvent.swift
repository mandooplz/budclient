//
//  ProjectSourceEvent.swift
//  BudClient
//
//  Created by 김민우 on 7/15/25.
//
import Foundation
import Values


// MARK: Value
package enum ProjectSourceEvent: Sendable {
    case added(SystemSourceDiff)
    case modified(SystemSourceDiff)
    case removed(SystemSourceDiff)
}
