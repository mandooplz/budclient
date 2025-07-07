//
//  Identity.swift
//  BudClient
//
//  Created by 김민우 on 7/4/25.
//
import Foundation


// MARK: Identity
public protocol Identity: Sendable, Hashable, Codable {
    associatedtype RawValue: Sendable, Hashable
    var value: RawValue { get }
}


public extension Identity where RawValue == UUID {
    var toString: String {
        value.uuidString
    }
}

public extension Identity where RawValue == String {
    var toString: String {
        value
    }
}
