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
    
    package func setName(_ value: String) async {
        logger.start()
        
        // capture
        guard id.isExist else {
            logger.failure("ActionSource가 존재하지 않아 실행 취소됩니다.")
            return
        }
        
        let actionSource = self.id
        let objectSource = self.owner
        let systemSource = objectSource.ref!.owner
        let projectSource = systemSource.ref!.owner
        
        let actionSourceDocRef = Firestore.firestore()
            .collection(DB.ProjectSources).document(projectSource.value)
            .collection(DB.SystemSources).document(systemSource.value)
            .collection(DB.ObjectSources).document(objectSource.value)
            .collection(DB.ActionSources).document(actionSource.value)
        
        // compute
        let updateFields: [String: Any] = [
            ActionSource.Data.name: value
        ]
        
        do {
            try await actionSourceDocRef.updateData(updateFields)
        } catch {
            logger.failure("ActionSource name 업데이트 실패\n\(error)")
            return
        }
    }
    
    var handler: EventHandler?
    package func appendHandler(requester: ObjectID,
                               _ handler: EventHandler) async {
        logger.start()
        
        // mutate
        self.handler = handler
    }
    
    
    // MARK: action
    package func notifyStateChanged() async {
        logger.start()
        
        return
    }
    
    package func duplicateAction() async {
        logger.start()
        
        // capture
        guard id.isExist else {
            logger.failure("ActionSource가 존재하지 않아 실행 취소됩니다.")
            return
        }
        
        let actionSource = self.id
        let objectSource = self.owner
        let systemSource = objectSource.ref!.owner
        let projectSource = systemSource.ref!.owner
        
        let firebaseDB = Firestore.firestore()
        
        let actionSourceCollectionRef = Firestore.firestore()
            .collection(DB.ProjectSources).document(projectSource.value)
            .collection(DB.SystemSources).document(systemSource.value)
            .collection(DB.ObjectSources).document(objectSource.value)
            .collection(DB.ActionSources)
        
        let actionSourceDocRef = actionSourceCollectionRef
            .document(actionSource.value)
        
        // compute
        do {
            let _ = try await firebaseDB.runTransaction { @Sendable transaction, _ in
                // get SourceData
                let sourceData: ActionSource.Data
                do {
                    sourceData = try transaction
                        .getDocument(actionSourceDocRef)
                        .data(as: ActionSource.Data.self)
                } catch {
                    logger.failure("ActionSource Data 가져오기 실패\n\(error)")
                    return
                }
                
                // create ActionSource
                let newData = ActionSource.Data(
                    name: sourceData.name
                )
                
                let newDocRef = actionSourceCollectionRef.document()
                
                do {
                    try transaction.setData(from: newData,
                                            forDocument: newDocRef)
                } catch {
                    logger.failure("새로운 ActionSource 생성 실패\n\(error)")
                    return
                }
                
                return
            }
        } catch {
            logger.failure("ActionSource 복제 실패\n\(error)")
            return
        }
    }
    package func removeAction() async {
        logger.start()
        
        // capture
        guard id.isExist else {
            logger.failure("ActionSource가 존재하지 않아 실행 취소됩니다.")
            return
        }
        
        let actionSource = self.id
        let objectSource = self.owner
        let systemSource = objectSource.ref!.owner
        let projectSource = systemSource.ref!.owner
        
        let actionSourceDocRef = Firestore.firestore()
            .collection(DB.ProjectSources).document(projectSource.value)
            .collection(DB.SystemSources).document(systemSource.value)
            .collection(DB.ObjectSources).document(objectSource.value)
            .collection(DB.ActionSources).document(actionSource.value)
        
        // compute
        do {
            try await actionSourceDocRef.delete()
        } catch {
            logger.failure("ActionSource 삭제 실패\n\(error)")
            return
        }
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
        
        init(target: ActionID = ActionID(),
             order: Int = 0,
             name: String = "New Action") {
            self.target = target
            self.order = order
            self.name = name
        }
        
        func getDiff(id: ActionSource.ID) -> ActionSourceDiff {
            let now = Date.now

            return .init(
                id: id,
                target: self.target,
                createdAt: createdAt?.dateValue() ?? now,
                updatedAt: updatedAt?.dateValue() ?? now,
                order: self.order,
                name: self.name)
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

