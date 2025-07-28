//
//  GetterSourceInterface.swift
//  BudClient
//
//  Created by 김민우 on 7/19/25.
//
import Foundation
import Values


// MARK: Interface
package protocol GetterSourceInterface: Sendable {
    associatedtype ID: GetterSourceIdentity where ID.Object == Self
    
    // MARK: state
    func setName(_ value: String) async
    func setParameters(_ value: [ParameterValue]) async
    func setResult(_ value: ValueID) async
    
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
    
    package let createdAt: Date
    package let updatedAt: Date
    package let order: Int
    
    package let name: String
    package let parameters: [ParameterValue]
    package let result: ValueID?
    
    package init(id: any GetterSourceIdentity, target: GetterID, createdAt: Date, updatedAt: Date, order: Int, name: String, parameters: [ParameterValue], result: ValueID? = nil) {
        self.id = id
        self.target = target
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.order = order
        self.name = name
        self.parameters = parameters
        self.result = result
    }
    
    @Server
    init(_ objectRef: GetterSourceMock) {
        self.id = objectRef.id
        self.target = objectRef.target
        
        self.createdAt = objectRef.createdAt
        self.updatedAt = objectRef.updatedAt
        self.order = objectRef.order
        
        self.name = objectRef.name
        self.parameters = objectRef.parameters
        self.result = objectRef.result
    }
}


package enum GetterSourceEvent: Sendable {
    case modified(GetterSourceDiff)
    case removed
}
