//
//  ObjectSourceInterface.swift
//  BudClient
//
//  Created by 김민우 on 7/11/25.
//
import Foundation
import Values


// MARK: Interface
package protocol ObjectSourceInterface: Sendable {
    associatedtype ID: ObjectSourceIdentity where ID.Object == Self
    
    func setHandler(_ handler: Handler<ObjectSourceEvent>) async
}


package protocol ObjectSourceIdentity: Sendable, Hashable {
    associatedtype Object: ObjectSourceInterface where Object.ID == Self
    
    var isExist: Bool { get async }
    var ref: Object? { get async }
}
