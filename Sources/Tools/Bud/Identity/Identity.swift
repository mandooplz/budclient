//
//  Identity.swift
//  BudClient
//
//  Created by 김민우 on 7/4/25.
//
import Foundation


// MARK: Identity
public protocol Identity: Sendable, Hashable {
    var value: UUID { get }
}


public extension Identity {
    var toString: String {
        value.uuidString
    }
}
