//
//  UserID.swift
//  BudClient
//
//  Created by 김민우 on 7/1/25.
//
import Foundation


// MARK: UserID
public struct UserID: Identity {
    public let value: String
    
    public init(_ value: String) {
        self.value = value
    }
    
    package init() {
        self.value = UUID().uuidString
    }
}

public extension String {
    func toUserID() -> UserID {
        .init(self)
    }
}
