//
//  Identity.swift
//  BudClient
//
//  Created by 김민우 on 7/4/25.
//
import Foundation


// MARK: Identity
public protocol Identity: Sendable, Hashable {
    associatedtype IDValue: Sendable, Hashable
    var value: IDValue { get }
}


public extension Identity where IDValue == UUID {
    var toString: String {
        value.uuidString
    }
}

public extension Identity where IDValue == String {
    var toString: String {
        value
    }
}
