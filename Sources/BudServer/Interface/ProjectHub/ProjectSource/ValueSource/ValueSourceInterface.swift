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
    func synchorize() async
}


package protocol ValueSourceIdentity: Sendable, Hashable {
    associatedtype Object: ValueSourceInterface where Object.ID == Self
    
    var isExist: Bool { get async }
    var ref: Object? { get async }
}


// MARK: Values
package enum ValueSourceEvent: Sendable {
    case modified(ValueSourceDiff)
}
package struct ValueSourceDiff: Sendable {
    
}


