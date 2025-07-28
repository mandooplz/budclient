//
//  ValueSourceInterface.swift
//  BudClient
//
//  Created by 김민우 on 7/17/25.
//
import Foundation
import Values


// MARK: Interface
package protocol ValueSourceInterface: Sendable, SyncInterface {
    associatedtype ID: ValueSourceIdentity where ID.Object == Self
    
    
    // MARK: state
    func appendHandler(requester: ObjectID, _ handler: Handler<ValueSourceEvent>) async
    
    
    // MARK: action
    func synchorize() async // 과연 필요한가.
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

public struct ValueSourceDiff: Sendable {
    package let id: any ValueSourceIdentity
    public let target: ValueID
    
    public let name: String
    public let description: String?
    
    public let fields: [ValueField]
}


public struct ValueField: Sendable, Hashable {
    public let name: String
    public let type: ValueID
    
    public init(name: String, type: ValueID) {
        self.name = name
        self.type = type
    }
}


