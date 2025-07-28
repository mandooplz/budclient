//
//  ValueSourceInterface.swift
//  BudClient
//
//  Created by 김민우 on 7/17/25.
//
import Foundation
import Values


// MARK: Interface
package protocol ValueSourceInterface: Sendable {
    associatedtype ID: ValueSourceIdentity where ID.Object == Self
    
    
    // MARK: state
    func setName(_ value: String) async
    func setDescription(_ value: String) async
    func setFields(_ value: [ValueField]) async
    
    func appendHandler(requester: ObjectID, _
                       handler: Handler<ValueSourceEvent>) async
    
    
    // MARK: action
    func removeValue() async
}


package protocol ValueSourceIdentity: Sendable, Hashable {
    associatedtype Object: ValueSourceInterface where Object.ID == Self
    
    var isExist: Bool { get async }
    var ref: Object? { get async }
}


// MARK: Values
package enum ValueSourceEvent: Sendable {
    case modified(ValueSourceDiff)
    case removed
}

package struct ValueSourceDiff: Sendable {
    package let id: any ValueSourceIdentity
    package let target: ValueID
    
    package let createdAt: Date
    package let updatedAt: Date
    package let order: Int
    
    package let name: String
    package let description: String?
    
    package let fields: [ValueField]
}


public struct ValueField: Sendable, Hashable, Codable {
    public let name: String
    public let type: ValueID
    
    public init(name: String, type: ValueID) {
        self.name = name
        self.type = type
    }
}


