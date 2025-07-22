//
//  SetterSourceInterface.swift
//  BudClient
//
//  Created by 김민우 on 7/22/25.
//
import Foundation
import Values


// MARK: Interface
package protocol SetterSourceInterface: Sendable {
    associatedtype ID: SetterSourceIdentity where ID.Object == Self
    
    // MARK: state

    
    // MARK: action
}


package protocol SetterSourceIdentity: Sendable, Hashable {
    associatedtype Object: SetterSourceInterface where Object.ID == Self
    
    var isExist: Bool { get async }
    var ref: Object? { get async }
}



// MARK: Value
package struct SetterSourceDiff: Sendable {
    package let id: any SetterSourceIdentity
    package let target: SetterID
    package let name: String
    
    package let parameters: [ParameterValue]
    
    @Server
    init(_ objectRef: SetterSourceMock) {
        self.id = objectRef.id
        self.target = objectRef.target
        self.name = objectRef.name
        
        self.parameters = objectRef.parameters
            .values
            .map { $0 }
    }
}


package enum SetterSourceEvent: Sendable {
    case modified(SetterSourceDiff)
    case removed
}
