//
//  RootSourceInterface.swift
//  BudClient
//
//  Created by 김민우 on 7/11/25.
//
import Foundation
import Values


// MARK: Interface
package protocol RootSourceInterface: Sendable {
    associatedtype ID: RootSourceIdentity where ID.Object == Self
}


package protocol RootSourceIdentity: Sendable, Hashable {
    associatedtype Object: RootSourceInterface where Object.ID == Self
    
    var isExist: Bool { get async }
    var ref: Object? { get async }
}

