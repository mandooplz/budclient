//
//  GetterSourceInterface.swift
//  BudClient
//
//  Created by 김민우 on 7/19/25.
//
import Foundation
import Values
import Collections


// MARK: Interface
package protocol GetterSourceInterface: Sendable {
    associatedtype ID: GetterSourceIdentity where ID.Object == Self
    
    // MARK: state
    func setName(_ value: String) async
    func appendHandler(requester: ObjectID, _ handler: Handler<GetterSourceEvent>) async

    
    // MARK: action
    func notifyStateChanged() async
    
    func duplicateGetter() async
    func removeGetter() async
}


package protocol GetterSourceIdentity: Sendable, Hashable {
    associatedtype Object: GetterSourceInterface where Object.ID == Self
    
    var isExist: Bool { get async }
    var ref: Object? { get async }
}



// MARK: Value
package struct GetterSourceDiff: Sendable {
    package let id: any GetterSourceIdentity
    package let target: GetterID
    package let name: String
    
    package let parameters: [ParameterValue]
    package let result: ValueType
    
    @Server
    init(_ objectRef: GetterSourceMock) {
        self.id = objectRef.id
        self.target = objectRef.target
        self.name = objectRef.name
        
        self.parameters = objectRef.parameters.values
            .map { $0 }
        self.result = objectRef.result
    }
}


package enum GetterSourceEvent: Sendable {
    case modified(GetterSourceDiff)
    case removed
}
