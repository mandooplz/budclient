//
//  ProjectSourceID.swift
//  BudClient
//
//  Created by 김민우 on 7/3/25.
//
import Foundation


// MARK: ProjectSourceID
public struct ProjectSourceID: Identity {
    public let value: String
    
    public init(_ value: String) {
        self.value = value
    }
    
    public init(uuid: UUID = UUID()) {
        self.value = uuid.uuidString
    }
}
