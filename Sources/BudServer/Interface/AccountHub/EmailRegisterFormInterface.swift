//
//  EmailRegisterFormInterface.swift
//  BudClient
//
//  Created by 김민우 on 7/11/25.
//
import Foundation
import Values


// MARK: Interface
package protocol EmailRegisterFormInterface: Sendable {
    associatedtype ID: EmailRegisterFormIdentity where ID.Object == Self
    
    // MARK: state
    func setEmail(_: String) async
    func setPassword(_: String) async
    
    // MARK: action
    func submit() async throws
    func remove() async throws
}

package protocol EmailRegisterFormIdentity: Sendable, Hashable {
    associatedtype Object: EmailRegisterFormInterface where Object.ID == Self
    
    var isExist: Bool { get async }
    var ref: Object? { get async }
}

