//
//  SetterSourceInterface.swift
//  BudClient
//
//  Created by 김민우 on 7/22/25.
//
import Foundation
import Values
import Collections


// MARK: Interface
package protocol SetterSourceInterface: Sendable {
    associatedtype ID: SetterSourceIdentity where ID.Object == Self
    
    // MARK: state
    func setName(_ value: String) async
    func setParameters(_ value: OrderedSet<ParameterValue>) async
    func appendHandler(requester: ObjectID, _ handler: Handler<SetterSourceEvent>) async
    
    
    // MARK: action
    func notifyStateChanged() async
    
    func duplicateSetter() async
    func removeSetter() async
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
    
    package let createdAt: Date
    package let updatedAt: Date
    package let order: Int
    
    package let name: String
    package let parameters: OrderedSet<ParameterValue>
    
    package init(id: any SetterSourceIdentity, target: SetterID, createdAt: Date, updatedAt: Date, order: Int, name: String, parameters: OrderedSet<ParameterValue>) {
        self.id = id
        self.target = target
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.order = order
        self.name = name
        self.parameters = parameters
    }
    
    @Server
    init(_ objectRef: SetterSourceMock) {
        self.id = objectRef.id
        self.target = objectRef.target
        
        self.createdAt = objectRef.createdAt
        self.updatedAt = objectRef.updatedAt
        self.order = objectRef.order
        
        self.name = objectRef.name
        self.parameters = objectRef.parameters.keys
    }
}


package enum SetterSourceEvent: Sendable {
    case modified(SetterSourceDiff)
    case removed

}
