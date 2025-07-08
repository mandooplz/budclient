//
//  BudCacheMock.swift
//  BudClient
//
//  Created by 김민우 on 6/28/25.
//
import Foundation
import Values
import BudServer


// MARK: BudCache
@Server
package final class BudCacheMock: Sendable {
    // MARK: core
    package nonisolated init() { }
    
    
    // MARK: state
    package var user: UserID?
}
