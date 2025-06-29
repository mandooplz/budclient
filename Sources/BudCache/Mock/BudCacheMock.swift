//
//  BudCacheMock.swift
//  BudClient
//
//  Created by 김민우 on 6/28/25.
//
import Foundation
import Tools
import BudServer


// MARK: BudCache
@MainActor
package final class BudCacheMock: Sendable {
    // MARK: core
    package static let shared = BudCacheMock()
    package init() { }
    
    
    // MARK: state
    package var userId: String?
}
