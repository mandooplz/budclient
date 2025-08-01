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
    func notifyStateChanged() async
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
    
    // MARK: core
    init(id: any ValueSourceIdentity, target: ValueID, createdAt: Date, updatedAt: Date, order: Int, name: String, description: String?, fields: [ValueField]) {
        self.id = id
        self.target = target
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.order = order
        self.name = name
        self.description = description
        self.fields = fields
    }
    
    @Server
    init(_ objectRef: ValueSourceMock) {
        self.id = objectRef.id
        self.target = objectRef.target
        
        self.createdAt = objectRef.createdAt
        self.updatedAt = objectRef.updatedAt
        self.order = objectRef.order
        
        self.name = objectRef.name
        self.description = objectRef.description
        self.fields = objectRef.fields
    }
}


public struct ValueField: Sendable, Hashable, Codable {
    public let name: String
    public let type: ValueID
    
    public init(name: String, type: ValueID) {
        self.name = name
        self.type = type
    }
}


