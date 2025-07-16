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
    
    func hasHandler(requester: ObjectID) async -> Bool
    func setHandler(requester: ObjectID, handler: Handler<SystemSourceEvent>) async
    func removeHandler(requester: ObjectID) async
    
    func notifyNameChanged() async
    
    // MARK: action
    func addSystemRight() async
    func addSystemLeft() async
    func addSystemTop() async
    func addSystemBottom() async
    
    func createNewObject() async
    
    func remove() async
}
