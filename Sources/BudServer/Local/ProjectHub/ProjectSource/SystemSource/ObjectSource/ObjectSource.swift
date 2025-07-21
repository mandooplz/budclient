//
//  ObjectSource.swift
//  BudClient
//
//  Created by 김민우 on 7/9/25.
//
import Foundation
import Values
import FirebaseFirestore
import Collections

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
        fatalError()
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
    
    package func createChildObject() async {
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
        package var parent: ObjectID?
        package var childs: OrderedSet<ObjectID>
        
        
        init(name: String, role: ObjectRole, parent: ObjectID? = nil) {
            self.name = name
            self.target = ObjectID()
            self.role = role
            self.parent = parent
            self.childs = []
            
            if role == .node && parent == nil {
                logger.failure("node에 해당하는 Object의 parent가 nil일 수 없습니다.")
            } else if role == .root && parent != nil {
                logger.failure("root에 해당하는 Object의 parent가 존재해서는 안됩니다.")
            }
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
