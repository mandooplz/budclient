//
//  SystemSourceEvent.swift
//  BudClient
//
//  Created by 김민우 on 7/15/25.
//
import Foundation
import Values


// MARK: Value
package enum SystemSourceEvent: Sendable {
    case added(ObjectSourceDiff)
    case modified(ObjectSourceDiff)
    case removed(ObjectSourceDiff)
}
