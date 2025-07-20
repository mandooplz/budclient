//
//  ObjectSource.swift
//  BudClient
//
//  Created by 김민우 on 7/9/25.
//
import Foundation
import Values
import FirebaseFirestore

private let logger = BudLogger("ObjectSource")


// MARK: Object
@MainActor
package final class ObjectSource: ObjectSourceInterface {
    // MARK: core
    init(id: ID) {
        self.id = id
        
        ObjectSourceManager.register(self)
    }
    func delete() {
        ObjectSourceManager.unregister(self.id)
    }
    
    
    // MARK: state
    package nonisolated let id: ID
    
    package func setName(_ value: String) async {
        logger.failure("미구현")
    }
    
    var listener: ListenerRegistration?
    var handler: EventHandler?
    package func setHandler(for requester: ObjectID, _ handler: EventHandler) {
        // Firebase를 통해 구독 구현
    }
    
    package func notifyNameChanged() async {
        logger.start()
        
        // Firebase에 의해 알아서 처리된다. 
    }
    package func synchronize(requester: ObjectID) async {
        logger.start()
        
        // Firebase에서 자체적으로 첫 이벤트들을 전송
        return
    }
    
    
    // MARK: action
    package func appendNewState() async {
        fatalError()
    }
    package func appendNewAction() async {
        fatalError()
    }

    
    
    // MARK: value
    package typealias EventHandler = Handler<ObjectSourceEvent>
    
    @MainActor
    package struct ID: ObjectSourceIdentity {
        let value: String
        nonisolated init(_ value: String) {
            self.value = value
        }
        
        package var isExist: Bool {
            ObjectSourceManager.container[self] != nil
        }
        package var ref: ObjectSource? {
            ObjectSourceManager.container[self]
        }
    }
    
    package struct Data: Codable {
        @DocumentID var id: String?
        package var target: ObjectID
        
        package var name: String
        package var role: ObjectRole
        
        
        init(name: String, role: ObjectRole) {
            self.name = name
            self.target = ObjectID()
            self.role = role
        }
    }
}


// MARK: ObjectManager
@MainActor
fileprivate final class ObjectSourceManager: Sendable {
    // MARK: state
    fileprivate static var container: [ObjectSource.ID: ObjectSource] = [:]
    fileprivate static func register(_ object: ObjectSource) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: ObjectSource.ID) {
        container[id] = nil
    }
}
