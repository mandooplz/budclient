//
//  SystemSourceInterface.swift
//  BudClient
//
//  Created by 김민우 on 7/11/25.
//
import Foundation
import Values


// MARK: Interface
package protocol SystemSourceInterface: Sendable {
    associatedtype ID: SystemSourceIdentity where ID.Object == Self
    
    // MARK: state
    func setName(_ value: String) async
    func setHandler(_ handler: Handler<SystemSourceEvent>) async
    
    func notifyNameChanged() async
    
    // MARK: action
    func addSystemRight() async
    func addSystemLeft() async
    func addSystemTop() async
    func addSystemBottom() async
    
    func removeSystem() async
}


package protocol SystemSourceIdentity: Sendable, Hashable {
    associatedtype Object: SystemSourceInterface where Object.ID == Self
    
    var isExist: Bool { get async }
    var ref: Object? { get async }
}

