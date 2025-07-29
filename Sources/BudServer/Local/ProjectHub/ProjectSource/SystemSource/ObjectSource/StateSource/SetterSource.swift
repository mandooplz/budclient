//
//  SetterSource.swift
//  BudClient
//
//  Created by 김민우 on 7/17/25.
//
import Foundation
import Values
import BudMacro
import FirebaseFirestore

private let logger = BudLogger("SetterSource")


// MARK: Object
@MainActor
package final class SetterSource: SetterSourceInterface {
    // MARK: core
    init(id: ID, target: SetterID, owner: StateSource.ID) {
        self.id = id
        self.target = target
        self.owner = owner
        
        SetterSourceManager.register(self)
    }
    func delete() {
        SetterSourceManager.unregister(self.id)
    }
    
    
    // MARK: state
    nonisolated let id: ID
    nonisolated let target: SetterID
    nonisolated let owner: StateSource.ID
    
    var handler: EventHandler?
    
    package func setName(_ value: String) async {
        logger.start()
        
        // capture
        guard id.isExist else {
            logger.failure("SetterSource가 존재하지 않아 실행 취소됩니다.")
            return
        }
        
        let setterSource = self.id
        let stateSource = self.owner
        let objectSource = stateSource.ref!.owner
        let systemSource = objectSource.ref!.owner
        let projectSource = systemSource.ref!.owner
        
        let setterSourceDocRef = Firestore.firestore()
            .collection(DB.ProjectSources).document(projectSource.value)
            .collection(DB.SystemSources).document(systemSource.value)
            .collection(DB.ObjectSources).document(objectSource.value)
            .collection(DB.StateSources).document(stateSource.value)
            .collection(DB.SetterSources).document(setterSource.value)
        
        let updateFields: [String: Any] = [
            SetterSource.Data.name: value
        ]
        
        // compute
        do {
            try await setterSourceDocRef.updateData(updateFields)
        } catch {
            logger.failure("SetterSource.name 업데이트 실패\n\(error)")
            return
        }
    }
    
    package func setParameters(_ value: [ParameterValue]) async {
        logger.start()
        
        // capture
        guard id.isExist else {
            logger.failure("SetterSource가 존재하지 않아 실행 취소됩니다.")
            return
        }
        
        let setterSource = self.id
        let stateSource = self.owner
        let objectSource = stateSource.ref!.owner
        let systemSource = objectSource.ref!.owner
        let projectSource = systemSource.ref!.owner
        
        let setterSourceDocRef = Firestore.firestore()
            .collection(DB.ProjectSources).document(projectSource.value)
            .collection(DB.SystemSources).document(systemSource.value)
            .collection(DB.ObjectSources).document(objectSource.value)
            .collection(DB.StateSources).document(stateSource.value)
            .collection(DB.SetterSources).document(setterSource.value)
        
        let updateFields: [String: Any] = [
            SetterSource.Data.parameters: value.encode()
        ]
        
        // compute
        do {
            try await setterSourceDocRef.updateData(updateFields)
        } catch {
            logger.failure("SetterSource.parameters 업데이트 실패\n\(error)")
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
    package func duplicateSetter() async {
        logger.start()
        
        // capture
        guard id.isExist else {
            logger.failure("SetterSource가 존재하지 않아 실행 취소됩니다.")
            return
        }
        
        let setterSource = self.id
        let stateSource = self.owner
        let objectSource = stateSource.ref!.owner
        let systemSource = objectSource.ref!.owner
        let projectSource = systemSource.ref!.owner
        
        let firebaseDB = Firestore.firestore()
        
        let setterSourceCollectionRef = firebaseDB
            .collection(DB.ProjectSources).document(projectSource.value)
            .collection(DB.SystemSources).document(systemSource.value)
            .collection(DB.ObjectSources).document(objectSource.value)
            .collection(DB.StateSources).document(stateSource.value)
            .collection(DB.SetterSources)
        
        let setterSourceDocRef = setterSourceCollectionRef
            .document(setterSource.value)
        
        // compute
        do {
            let _ = try await firebaseDB.runTransaction { @Sendable transaction, _ in
                // get SourceData
                let sourceData: SetterSource.Data
                do {
                    sourceData = try transaction
                        .getDocument(setterSourceDocRef)
                        .data(as: SetterSource.Data.self)
                } catch {
                    logger.failure("SourceData 가져오기 실패\n\(error)")
                    return
                }
                
                // create SetterSource
                let newData = SetterSource.Data(
                    name: sourceData.name,
                    parameters: sourceData.parameters
                )
                
                let newDocRef = setterSourceCollectionRef.document()
                
                do {
                    try transaction.setData(from: newData,
                                            forDocument: newDocRef)
                } catch {
                    logger.failure("새로운 SetterSource 생성 실패\n\(error)")
                    return
                }
                
                // return
                return
            }
        } catch {
            logger.failure("SetterSource 복제 실패\n\(error)")
            return
        }
    }
    package func removeSetter() async {
        logger.start()
        
        // capture
        guard id.isExist else {
            logger.failure("SetterSource가 존재하지 않아 실행 취소됩니다.")
            return
        }
        
        let setterSource = self.id
        let stateSource = self.owner
        let objectSource = stateSource.ref!.owner
        let systemSource = objectSource.ref!.owner
        let projectSource = systemSource.ref!.owner
        
        let setterSourceDocRef = Firestore.firestore()
            .collection(DB.ProjectSources).document(projectSource.value)
            .collection(DB.SystemSources).document(systemSource.value)
            .collection(DB.ObjectSources).document(objectSource.value)
            .collection(DB.StateSources).document(stateSource.value)
            .collection(DB.SetterSources).document(setterSource.value)
        
        // compute
        do {
            try await setterSourceDocRef.delete()
        } catch {
            logger.failure("SetterSource 삭제 실패\n\(error)")
            return
        }
    }
    
    // MARK: value
    package typealias EventHandler = Handler<SetterSourceEvent>
    
    @MainActor
    package struct ID: SetterSourceIdentity {
        let value: String
        nonisolated init(_ value: String) {
            self.value = value
        }
        
        package var isExist: Bool {
            SetterSourceManager.container[self] != nil
        }
        package var ref: SetterSource? {
            SetterSourceManager.container[self]
        }
    }
    @ShowState
    package struct Data: Codable {
        @DocumentID var id: String?
        var target: SetterID
        
        @ServerTimestamp var createdAt: Timestamp?
        @ServerTimestamp var updatedAt: Timestamp?
        var order: Int
        
        var name: String
        var parameters: [ParameterValue]
        
        // MARK: core
        init(name: String = "New Setter",
             parameters: [ParameterValue] = []) {
            self.target = SetterID()
            self.order = 0
            
            self.name = name
            self.parameters = parameters
        }
        
        // MARK: operator
        func getDiff(id: SetterSource.ID) -> SetterSourceDiff {
            let now = Date.now
            
            return .init(
                id: id,
                target: self.target,
                createdAt: createdAt?.dateValue() ?? now,
                updatedAt: updatedAt?.dateValue() ?? now,
                order: self.order,
                name: self.name,
                parameters: self.parameters)
        }
    }
}


// MARK: ObjectManager
@MainActor
fileprivate final class SetterSourceManager: Sendable {
    // MARK: state
    fileprivate static var container: [SetterSource.ID: SetterSource] = [:]
    fileprivate static func register(_ object: SetterSource) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: SetterSource.ID) {
        container[id] = nil
    }
}
