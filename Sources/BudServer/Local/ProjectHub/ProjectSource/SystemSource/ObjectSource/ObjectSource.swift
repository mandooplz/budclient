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
import BudMacro

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
    var listener: ListenerRegistration?
    var handler: EventHandler?
    
    var states: [StateID: StateSource.ID] = [:]
    var actions: [ActionID: ActionSource.ID] = [:]
    
    package func setName(_ value: String) async {
        logger.failure("미구현")
    }
    
    
    package func appendHandler(requester: ObjectID, _ handler: EventHandler) {
        logger.start()
        
        // capture
        let firebaseDB = Firestore.firestore()
        
        // let stateSourceCollectionRef
        // let actionSourceCollectionRef
        
        // compute
        // stateSourceCollectionRef 스냅샷 리스너 등록
        // actionSourceCollectionRef 스냅샷 리스너 등록
        
    }
    package func notifyStateChanged() async {
        logger.start()
        
        // Firebase에 의해 알아서 처리된다.
    }
    
    package func registerSync(_ object: ObjectID) async {
        fatalError()
    }
    
    
    
    // MARK: action
    package func synchronize() async {
        logger.start()
        
        // Firebase에서 자체적으로 첫 이벤트들을 전송
        return
    }
    
    package func appendNewState() async {
        fatalError("구현 예정")
    }
    package func appendNewAction() async {
        fatalError("구현 예정")
    }
    
    package func createChildObject() async {
        fatalError("구현 예정")
    }
    
    package func removeObject() async {
        fatalError("구현 예정")
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
    
    @ShowState
    package struct Data: Codable {
        @DocumentID var id: String?
        @ServerTimestamp var createdAt: Timestamp?
        @ServerTimestamp var updatedAt: Timestamp?
        var order: Int
        
        package var target: ObjectID
        
        package var name: String
        package var role: ObjectRole
        package var parent: ObjectID?
        package var childs: OrderedSet<ObjectID>
        
        
        init(order: Int = 0,
             name: String,
             role: ObjectRole,
             parent: ObjectID? = nil) {
            self.order = order
            self.target = ObjectID()
            
            self.name = name
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
