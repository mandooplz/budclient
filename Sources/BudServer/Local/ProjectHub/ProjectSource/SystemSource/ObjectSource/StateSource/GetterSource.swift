//
//  GetterSource.swift
//  BudClient
//
//  Created by 김민우 on 7/17/25.
//
import Foundation
import Collections
import BudMacro
import FirebaseFirestore
import Values

private let logger = BudLogger("GetterSource")


// MARK: Object
@MainActor
package final class GetterSource: GetterSourceInterface {
    // MARK: core
    init(id: ID, target: GetterID, owner: StateSource.ID) {
        self.id = id
        self.target = target
        self.owner = owner
        
        GetterSourceManager.register(self)
    }
    func delete() {
        GetterSourceManager.unregister(self.id)
    }
    
    // MARK: state
    nonisolated let id: ID
    nonisolated let target: GetterID
    nonisolated let owner: StateSource.ID
    
    var handler: EventHandler?
    package func setName(_ value: String) async {
        fatalError()
    }
    package func setParameters(_ value: OrderedSet<ParameterValue>) async {
        fatalError()
    }
    package func setResult(_ value: ValueType) async {
        fatalError()
    }
    
    package func appendHandler(requester: ObjectID,
                               _ handler: Handler<GetterSourceEvent>) async {
        fatalError()
    }
    
    // MARK: action
    package func notifyStateChanged() async {
        fatalError()
    }

    package func duplicateGetter() async {
        fatalError()
    }
    package func removeGetter() async {
        fatalError()
    }

    
    // MARK: value
    package typealias EventHandler = Handler<GetterSourceEvent>
    @MainActor
    package struct ID: GetterSourceIdentity {
        let value: String
        nonisolated init(_ value: String) {
            self.value = value
        }
        
        package var isExist: Bool {
            GetterSourceManager.container[self] != nil
        }
        package var ref: GetterSource? {
            GetterSourceManager.container[self]
        }
    }
    @ShowState
    package struct Data: Codable {
        @DocumentID var id: String?
        var target: GetterID
        
        @ServerTimestamp var createdAt: Timestamp?
        @ServerTimestamp var updatedAt: Timestamp?
        var order: Int
        
        var name: String
        var parameters: OrderedSet<ParameterValue>
        var result: ValueType
        
        func getDiff(id: GetterSource.ID) throws -> GetterSourceDiff {
            guard let createdAt = self.createdAt?.dateValue(),
                  let updatedAt = self.updatedAt?.dateValue() else {
                throw Error.timeStampParseFailed
            }
            
            return .init(
                id: id,
                target: self.target,
                createdAt: createdAt,
                updatedAt: updatedAt,
                order: self.order,
                name: self.name,
                parameters: self.parameters,
                result: self.result)
        }
        
        enum Error: Swift.Error {
            case timeStampParseFailed
        }
    }
}


// MARK: ObjectManager
@MainActor
fileprivate final class GetterSourceManager: Sendable {
    // MARK: state
    fileprivate static var container: [GetterSource.ID: GetterSource] = [:]
    fileprivate static func register(_ object: GetterSource) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: GetterSource.ID) {
        container[id] = nil
    }
}



