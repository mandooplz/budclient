//
//  BudClientInfoFormInterface.swift
//  BudClient
//
//  Created by 김민우 on 7/18/25.
//
import Foundation


// MARK: Interface
package protocol BudClientInfoFormInterface: Sendable {
    associatedtype ID: BudClientInfoFormIdentity where ID.Object == Self
    
    // MARK: core
    init() async
    func delete() async
    
    
    // MARK: state
    nonisolated var id: ID { get async }
    
    var googleClientId: String? { get async }
    
    
    // MARK: action
    func fetchGoogleClientId() async
}


package protocol BudClientInfoFormIdentity: Sendable, Hashable {
    associatedtype Object: BudClientInfoFormInterface where Object.ID == Self
    
    var isExist: Bool { get async }
    var ref: Object? { get async }
}


// MARK: Values
package enum BudClientInfoFormError: Swift.Error {
    case unknown(Error)
}

