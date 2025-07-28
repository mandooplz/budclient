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
        logger.start()
        
        // capture
        guard id.isExist else {
            logger.failure("GetterSource가 존재하지 않아 실행 취소됩니다.")
            return
        }
        
        let getterSource = self.id
        let stateSource = self.owner
        let objectSource = stateSource.ref!.owner
        let systemSource = objectSource.ref!.owner
        let projectSource = systemSource.ref!.owner
        
        let getterSourceDocRef = Firestore.firestore()
            .collection(DB.ProjectSources).document(projectSource.value)
            .collection(DB.SystemSources).document(systemSource.value)
            .collection(DB.ObjectSources).document(objectSource.value)
            .collection(DB.StateSources).document(stateSource.value)
            .collection(DB.GetterSources).document(getterSource.value)
        
        let updateFields: [String: Any] = [
            GetterSource.Data.name : value
        ]
        
        // compute
        do {
            try await getterSourceDocRef.updateData(updateFields)
        } catch {
            logger.failure("GetterSource.name 업데이트 실패\n\(error)")
            return
        }
        
    }
    package func setParameters(_ value: OrderedSet<ParameterValue>) async {
        logger.start()
        
        // capture
        guard id.isExist else {
            logger.failure("GetterSource가 존재하지 않아 실행 취소됩니다.")
            return
        }
        
        let getterSource = self.id
        let stateSource = self.owner
        let objectSource = stateSource.ref!.owner
        let systemSource = objectSource.ref!.owner
        let projectSource = systemSource.ref!.owner
        
        let getterSourceDocRef = Firestore.firestore()
            .collection(DB.ProjectSources).document(projectSource.value)
            .collection(DB.SystemSources).document(systemSource.value)
            .collection(DB.ObjectSources).document(objectSource.value)
            .collection(DB.StateSources).document(stateSource.value)
            .collection(DB.GetterSources).document(getterSource.value)
        
        let updateFields: [String: Any] = [
            "parameters" : value.encode()
        ]
        
        // compute
        do {
            try await getterSourceDocRef.updateData(updateFields)
        } catch {
            logger.failure("GetterSource.parameters 업데이트 실패\n\(error)")
            return
        }
    }
    package func setResult(_ value: ValueType) async {
        logger.start()
        
        // capture
        guard id.isExist else {
            logger.failure("GetterSource가 존재하지 않아 실행 취소됩니다.")
            return
        }
        
        let getterSource = self.id
        let stateSource = self.owner
        let objectSource = stateSource.ref!.owner
        let systemSource = objectSource.ref!.owner
        let projectSource = systemSource.ref!.owner
        
        let getterSourceDocRef = Firestore.firestore()
            .collection(DB.ProjectSources).document(projectSource.value)
            .collection(DB.SystemSources).document(systemSource.value)
            .collection(DB.ObjectSources).document(objectSource.value)
            .collection(DB.StateSources).document(stateSource.value)
            .collection(DB.GetterSources).document(getterSource.value)
        
        let updateFields: [String: Any] = [
            GetterSource.Data.result : value.encode()
        ]
        
        // compute
        do {
            try await getterSourceDocRef.updateData(updateFields)
        } catch {
            logger.failure("GetterSource.result 업데이트 실패\n\(error)")
            return
        }
    }
    
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

    package func duplicateGetter() async {
        logger.start()
        
        // capture
        guard id.isExist else {
            logger.failure("GetterSource가 존재하지 않아 실행 취소됩니다.")
            return
        }
        
        let getterSource = self.id
        let stateSource = self.owner
        let objectSource = stateSource.ref!.owner
        let systemSource = objectSource.ref!.owner
        let projectSource = systemSource.ref!.owner
        
        let firebaseDB = Firestore.firestore()
        
        let getterSourceCollectionRef = firebaseDB
            .collection(DB.ProjectSources).document(projectSource.value)
            .collection(DB.SystemSources).document(systemSource.value)
            .collection(DB.ObjectSources).document(objectSource.value)
            .collection(DB.StateSources).document(stateSource.value)
            .collection(DB.GetterSources)
        
        let getterSourceDocRef = getterSourceCollectionRef
            .document(getterSource.value)
        
        
        // compute
        do {
            let _ = try await firebaseDB.runTransaction { @Sendable transaction, _ in
                // get SourceData
                let sourceData: GetterSource.Data
                do {
                    sourceData = try transaction
                        .getDocument(getterSourceDocRef)
                        .data(as: GetterSource.Data.self)
                } catch {
                    logger.failure("SourceData 가져오기 실패\n\(error)")
                    return
                }
                
                // create SetterSource
                let newData = GetterSource.Data(
                    name: sourceData.name,
                    parameters: sourceData.parameters,
                    result: sourceData.result
                )
                
                let newDocRef = getterSourceCollectionRef.document()
                
                do {
                    try transaction.setData(from: newData,
                                            forDocument: newDocRef)
                } catch {
                    logger.failure("새로운 GetterSource 셍성 실패\n\(error)")
                    return
                }
                
                // return
                return
            }
        } catch {
            logger.failure("GetterSource 복제 실패\n\(error)")
            return
        }
        
    }
    package func removeGetter() async {
        logger.start()
        
        // capture
        guard id.isExist else {
            logger.failure("GetterSource가 존재하지 않아 실행 취소됩니다.")
            return
        }
        
        let getterSource = self.id
        let stateSource = self.owner
        let objectSource = stateSource.ref!.owner
        let systemSource = objectSource.ref!.owner
        let projectSource = systemSource.ref!.owner
        
        let getterSourceDocRef = Firestore.firestore()
            .collection(DB.ProjectSources).document(projectSource.value)
            .collection(DB.SystemSources).document(systemSource.value)
            .collection(DB.ObjectSources).document(objectSource.value)
            .collection(DB.StateSources).document(stateSource.value)
            .collection(DB.GetterSources).document(getterSource.value)
        
        // compute
        do {
            try await getterSourceDocRef.delete()
        } catch {
            logger.failure("GetterSource 삭제 실패\n\(error)")
            return
        }
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
        
        // MARK: core
        init(name: String = "New Getter",
             parameters: OrderedSet<ParameterValue> = [],
             result: ValueType = .void) {
            self.target = GetterID()
            self.order = 0
            
            self.name = name
            self.parameters = parameters
            self.result = result
        }
        
        
        // MARK: operator
        func getDiff(id: GetterSource.ID) -> GetterSourceDiff {
            let now = Date.now
            
            return .init(
                id: id,
                target: self.target,
                createdAt: createdAt?.dateValue() ?? now,
                updatedAt: updatedAt?.dateValue() ?? now,
                order: self.order,
                name: self.name,
                parameters: self.parameters,
                result: self.result)
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



