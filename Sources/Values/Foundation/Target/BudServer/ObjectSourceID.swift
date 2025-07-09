//
//  ObjectSourceID.swift
//  BudClient
//
//  Created by 김민우 on 7/9/25.
//
import Foundation


// MARK: ObjectSourceID
public struct ObjectSourceID: Identity {
    public var value: UUID
    
    public init(value: UUID = UUID()) {
        self.value = value
    }
}
