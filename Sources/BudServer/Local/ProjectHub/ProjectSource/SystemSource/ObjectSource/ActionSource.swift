//
//  ActionSource.swift
//  BudClient
//
//  Created by 김민우 on 7/17/25.
//
import Foundation
import Values
import BudMacro
import FirebaseFirestore

private let logger = BudLogger("ActionSource")


// MARK: Object
@MainActor
package final class ActionSource: ActionSourceInterface {
    // MARK: core
    init(id: ID, target: ActionID, owner: ObjectSource.ID) {
        self.id = id
        self.target = target
        self.owner = owner
        
        ActionSourceManager.register(self)
    }
    func delete() {
        ActionSourceManager.unregister(self.id)
    }
    
    
    // MARK: state
    nonisolated let id: ID
    nonisolated let target: ActionID
    nonisolated let owner: ObjectSource.ID
    
    // MARK: action
    package func setName(_ value: String) async {
        fatalError()
    }
    
    var handler: EventHandler?
    package func setHandler(requester: Values.ObjectID, _ handler: Values.Handler<ActionSourceEvent>) async {
        fatalError()
    }
    
    package func notifyStateChanged() async {
        logger.start()
        
        // Firebase에서 자체적으로 처리해준다.
        
        return
    }
    package func duplicateAction() async {
        fatalError()
    }
    package func removeAction() async {
        fatalError()
    }
    
    // MARK: value
    @MainActor
    package struct ID: ActionSourceIdentity {
        let value: String
        nonisolated init(_ value: String) {
            self.value = value
        }
        
        package var isExist: Bool {
            ActionSourceManager.container[self] != nil
        }
        package var ref: ActionSource? {
            ActionSourceManager.container[self]
        }
    }
    @ShowState
    package struct Data: Codable {
        @DocumentID var id: String?
        var target: ActionID
        
        @ServerTimestamp var createdAt: Timestamp?
        @ServerTimestamp var updatedAt: Timestamp?
        var order: Int
        
        var name: String
        
        func getDiff(id: ActionSource.ID) throws -> ActionSourceDiff {
            guard let createdAt = self.createdAt?.dateValue(),
                  let updatedAt = self.updatedAt?.dateValue() else {
                throw Error.timestampParseFailed
            }
            
            return .init(
                id: id,
                target: self.target,
                createdAt: createdAt,
                updatedAt: updatedAt,
                order: self.order,
                name: self.name)
        }
        
        enum Error: Swift.Error {
            case timestampParseFailed
        }
    }
    
    package typealias EventHandler = Handler<ActionSourceEvent>
}


// MARK: ObjectManager
@MainActor
fileprivate final class ActionSourceManager: Sendable {
    // MARK: state
    fileprivate static var container: [ActionSource.ID: ActionSource] = [:]
    fileprivate static func register(_ object: ActionSource) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: ActionSource.ID) {
        container[id] = nil
    }
}

