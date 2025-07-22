//
//  SyncInterface.swift
//  BudClient
//
//  Created by 김민우 on 7/22/25.
//
import Foundation


// MARK: Protocol
package protocol SyncInterface: Sendable {
    // MARK: state
    func registerSync(_ object: ObjectID) async
    
    // MARK: action
    func synchronize() async
}
