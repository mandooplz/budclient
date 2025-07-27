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
    init(id: ID, target: ObjectID, owner: SystemSource.ID) {
        self.id = id
        self.target = target
        self.owner = owner
        
        ObjectSourceManager.register(self)
    }
    func delete() {
        ObjectSourceManager.unregister(self.id)
    }
    
    
    // MARK: state
    package nonisolated let id: ID
    nonisolated let target: ObjectID
    nonisolated let owner: SystemSource.ID
    
    var listener: EventListener?
    var handler: EventHandler?
    
    var states: [StateID: StateSource.ID] = [:]
    var actions: [ActionID: ActionSource.ID] = [:]
    
    package func setName(_ value: String) async {
        logger.start()
        
        // capture
        guard id.isExist else {
            logger.failure("ObjectSource가 존재하지 않아 실행 취소됩니다.")
            return
        }
    }
    
    
    package func appendHandler(requester: ObjectID,
                               _ handler: EventHandler) {
        logger.start()
        
        // capture
        guard id.isExist else {
            logger.failure("ObjectSource가 존재하지 않아 실행취소됩니다.")
            return
        }
        guard listener == nil else {
            logger.failure("StateSource, ActionSource의 Firebase 리스너가 이미 존재합니다.")
            return
        }
        let me = self.id
        
        let systemSourceRef = self.owner.ref!
        let projectSourceRef = systemSourceRef.owner.ref!
        
        let objectSourceDocRef = Firestore.firestore()
            .collection(DB.ProjectSources).document(projectSourceRef.id.value)
            .collection(DB.SystemSources).document(systemSourceRef.id.value)
            .collection(DB.ObjectSources).document(self.id.value)
        
        // compute
        let stateListener = objectSourceDocRef
            .collection(DB.StateSources)
            .addSnapshotListener { snapshot, error in
                guard let snapshot else {
                    logger.failure("SnapshotListener Error: \(error!))")
                    return
                }
                
                snapshot.documentChanges.forEach { change in
                    // get StateSource
                    let documentId = change.document.documentID
                    let stateSource = StateSource.ID(documentId)
                    
                    // get StateSource.Data
                    let data: StateSource.Data
                    let diff: StateSourceDiff
                    do {
                        data = try change.document.data(as: StateSource.Data.self)
                        diff = try data.getDiff(id: stateSource)
                    } catch {
                        logger.failure("StateSource 디코딩 실패\n\(error)")
                        return
                    }
                    
                    // event
                    switch change.type {
                    case .added:
                        // create StateSource
                        let stateSourceRef = StateSource(id: stateSource,
                                                         target: diff.target,
                                                         owner: me)
                        me.ref?.states[diff.target] = stateSourceRef.id
                        
                        // notify
                        me.ref?.handler?.execute(.stateAdded(diff))
                    case .modified:
                        // notify
                        stateSource.ref?.handler?.execute(.modified(diff))
                    case .removed:
                        // notify
                        stateSource.ref?.handler?.execute(.removed)
                        
                        // remove StateSource
                        stateSource.ref?.delete()
                        me.ref?.states[diff.target] = nil
                    }
                }
            }
        
        let actionListener = objectSourceDocRef
            .collection(DB.ActionSources)
            .addSnapshotListener { snapshot, error in
                guard let snapshot else {
                    logger.failure("SnapshotListener Error: \(error!))")
                    return
                }
                
                snapshot.documentChanges.forEach { change in
                    // get ActionSource
                    let documentId = change.document.documentID
                    let actionSource = ActionSource.ID(documentId)
                    
                    // get StateSource.Data
                    let data: ActionSource.Data
                    let diff: ActionSourceDiff
                    do {
                        data = try change.document.data(as: ActionSource.Data.self)
                        diff = try data.getDiff(id: actionSource)
                    } catch {
                        logger.failure("ActionSource 디코딩 실패\n\(error)")
                        return
                    }
                    
                    // event
                    switch change.type {
                    case .added:
                        // create StateSource
                        let actionSourceRef = ActionSource(id: actionSource,
                                                         target: diff.target,
                                                         owner: me)
                        me.ref?.actions[diff.target] = actionSourceRef.id
                        
                        // notify
                        me.ref?.handler?.execute(.actionAdded(diff))
                    case .modified:
                        // notify
                        actionSource.ref?.handler?.execute(.modified(diff))
                    case .removed:
                        // notify
                        actionSource.ref?.handler?.execute(.removed)
                        
                        // remove StateSource
                        actionSource.ref?.delete()
                        me.ref?.actions[diff.target] = nil
                    }
                }
            }
        
        // mutate
        self.handler = handler
        self.listener = .init(state: stateListener,
                              action: actionListener)
    }
    
    package func registerSync(_ object: ObjectID) async {
        logger.start()
        
        logger.failure("Firebase에 의해 알아서 처리됩니다.")
    }
    
    
    
    // MARK: action
    package func synchronize() async {
        logger.start()
        
        logger.failure("Firebase에 의해 알아서 처리됩니다.")
    }
    package func notifyStateChanged() async {
        logger.start()
        
        logger.failure("Firebase에 의해 알아서 처리됩니다.")
    }
    
    package func appendNewState() async {
        logger.start()
        
        // capture
        guard id.isExist else {
            logger.failure("ObjectSource가 존재하지 않아 실행 취소됩니다.")
            return
        }
        let systemSourceRef = self.owner.ref!
        let projectSourceRef = systemSourceRef.owner.ref!
        
        let stateSourceCollectionRef = Firestore.firestore()
            .collection(DB.ProjectSources).document(projectSourceRef.id.value)
            .collection(DB.SystemSources).document(systemSourceRef.id.value)
            .collection(DB.ObjectSources).document(self.id.value)
            .collection(DB.StateSources)
        
        // compute
        do {
            let newDocData = StateSource.Data()
            try stateSourceCollectionRef.addDocument(from: newDocData)
        } catch {
            logger.failure(error)
            return
        }
    }
    package func appendNewAction() async {
        logger.start()
        
        // capture
        guard id.isExist else {
            logger.failure("ObjectSource가 존재하지 않아 실행 취소됩니다.")
            return
        }
        let systemSourceRef = self.owner.ref!
        let projectSourceRef = systemSourceRef.owner.ref!
        
        let actionSourceColletionRef = Firestore.firestore()
            .collection(DB.ProjectSources).document(projectSourceRef.id.value)
            .collection(DB.SystemSources).document(systemSourceRef.id.value)
            .collection(DB.ObjectSources).document(self.id.value)
            .collection(DB.ActionSources)
        
        // compute
        do {
            let newDocData = ActionSource.Data()
            try actionSourceColletionRef.addDocument(from: newDocData)
        } catch {
            logger.failure(error)
            return
        }
    }
    
    package func createChildObject() async {
        logger.start()
        
        // capture
        guard id.isExist else {
            logger.failure("ObjectSource가 존재하지 않아 실행 취소됩니다.")
            return
        }
        let me = self.id
        let myTarget = self.target
        
        let systemSourceRef = self.owner.ref!
        let projectSourceRef = systemSourceRef.owner.ref!
        
        let objectSourceCollectionRef = Firestore.firestore()
            .collection(DB.ProjectSources).document(projectSourceRef.id.value)
            .collection(DB.SystemSources).document(systemSourceRef.id.value)
            .collection(DB.ObjectSources)
        
        let objectSourceDocRef = objectSourceCollectionRef
            .document(self.id.value)
        
        // compute
        do {
            // 1. 새로운 자식 객체의 데이터 모델 생성
            //    - role은 .node로, parent는 현재 객체의 target ID로 설정합니다.
            let newChildData = ObjectSource.Data(role: .node, parent: myTarget)
            
            // 2. 새로운 자식 문서에 대한 참조 생성 (아직 서버에 생성되지는 않음)
            //    - document()를 호출하여 Firestore가 자동으로 고유 ID를 생성하도록 합니다.
            let newChildDocRef = objectSourceCollectionRef.document()
            
            // 3. WriteBatch를 사용하여 여러 쓰기 작업을 원자적으로 묶습니다.
            let batch = Firestore.firestore().batch()
            
            // 작업 1: 새로운 자식 문서를 생성합니다.
            // Codable 모델을 직접 사용하여 데이터를 설정합니다.
            try batch.setData(from: newChildData,
                              forDocument: newChildDocRef)
            
            // 작업 2: 부모 문서의 'childs' 배열에 새로운 자식의 target ID를 추가합니다.
            // FieldValue.arrayUnion을 사용하여 원자적으로 업데이트합니다.
            batch.updateData([
                "childs": FieldValue.arrayUnion([newChildData.target])
            ], forDocument: objectSourceDocRef)
            
            // 4. Batch 작업을 서버에 커밋(전송)합니다.
            try await batch.commit()
            
            logger.end("성공: 자식 객체(\(newChildDocRef.documentID))를 생성하고 부모(\(self.id.value))에 연결했습니다.")
            
        } catch {
            // 작업 중 하나라도 실패하면 전체가 롤백됩니다.
            logger.failure("자식 객체 생성 실패: \(error.localizedDescription)")
            return
        }
    }
    
    package func removeObject() async {
        // root node에 따라 다르게 적용
        fatalError("구현 예정")
    }

    
    
    // MARK: value
    package typealias EventHandler = Handler<ObjectSourceEvent>
    struct EventListener {
        let state: ListenerRegistration
        let action: ListenerRegistration
        
        init(state: ListenerRegistration, action: ListenerRegistration) {
            self.state = state
            self.action = action
        }
    }
    
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
        package var target: ObjectID
        
        @ServerTimestamp var createdAt: Timestamp?
        @ServerTimestamp var updatedAt: Timestamp?
        var order: Int
        
        package var name: String
        package var role: ObjectRole
        package var parent: ObjectID?
        package var childs: OrderedSet<ObjectID>
        
        init(order: Int = 0,
             name: String = "New Object",
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
