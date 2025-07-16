//
//  ActionID.swift
//  BudClient
//
//  Created by 김민우 on 7/7/25.
//
import Foundation


// MARK: GetterID
public struct ActionID: Identity {
    public let value: UUID
    public init(_ value: UUID = UUID()) {
        self.value = value
    }
}


public struct ValueTypeID: Identity {
    public let value: UUID
    public init(_ value: UUID = UUID()) {
        self.value = value
    }
}


public struct ObjectTypeID: Identity {
    public let value: UUID
    public init(_ value: UUID = UUID()) {
        self.value = value
    }
}
