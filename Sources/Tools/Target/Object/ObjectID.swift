//
//  ObjectID.swift
//  BudClient
//
//  Created by 김민우 on 7/4/25.
//
import Foundation


// MARK: ObjectID
public struct ObjectID: Identity, Codable {
    public let value: UUID
    
    public init(_ value: UUID = UUID()) {
        self.value = value
    }
    
    public init(_ fromString: String) throws(Error) {
        guard let value = UUID(uuidString: fromString) else {
            throw Error.invalidUUIDString
        }
        self.value = value
    }
    
    public enum Error: String, Swift.Error {
        case invalidUUIDString
    }
}
