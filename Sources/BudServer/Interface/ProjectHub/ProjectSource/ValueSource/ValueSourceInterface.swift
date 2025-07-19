//
//  ValueSourceInterface.swift
//  BudClient
//
//  Created by 김민우 on 7/17/25.
//
import Foundation


// MARK: Interface
package protocol ValueSourceInterface: Sendable {
    associatedtype ID: ValueSourceIdentity where ID.Object == Self
}


package protocol ValueSourceIdentity: Sendable, Hashable {
    associatedtype Object: ValueSourceInterface where Object.ID == Self
    
    var isExist: Bool { get async }
    var ref: Object? { get async }
}


// MARK: Values
package struct ValueSourceDiff: Sendable {
    
}


