//
//  IDRepresentable.swift
//  BudClient
//
//  Created by 김민우 on 7/4/25.
//
import Foundation


// MARK: IDRepresentable
public protocol IDRepresentable: Sendable, Hashable, Codable {
    associatedtype RawValue: Sendable, Hashable
    var value: RawValue { get }
}


public extension IDRepresentable {
    func encode() -> [String:Any] {
        ["value": value]
    }
}



public extension IDRepresentable where RawValue == UUID {
    var toString: String {
        value.uuidString
    }
}
public extension IDRepresentable where RawValue == String {
    var toString: String {
        value
    }
}
