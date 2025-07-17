//
//  SystemSource.swift
//  BudClient
//
//  Created by 김민우 on 7/7/25.
//
import Foundation
import Values
import FirebaseFirestore
import BudMacro

private let logger = WorkFlow.getLogger(for: "SystemSource")


// MARK: Object
@MainActor
package final class SystemSource: SystemSourceInterface {
    // MARK: core
    init(id: ID, target: SystemID, parent: ProjectSource.ID) {
        self.id = id
        self.target = target
        self.parent = parent
        
        SystemSourceManager.register(self)
    }
    func delete() {
        listener?.remove()
        
        SystemSourceManager.unregister(self.id)
    }
    
    
    // MARK: state
    nonisolated let id: ID
    nonisolated let target: SystemID
    nonisolated let parent: ProjectSource.ID
    
    package func setName(_ value: String) {
        logger.start()
        
        // compute
        let db = Firestore.firestore()
        let docRef = db.collection(DB.projectSources)
            .document(parent.value)
            .collection(DB.systemSources)
            .document(id.value)
        
        let updateData: [String: Any] = [
            Data.name : value
        ]
        
        docRef.updateData(updateData)
    }
    
    package var objects: [ObjectID: ObjectSource.ID] = [:]
    
    var listener: ListenerRegistration?
    var handler: EventHandler?
    
    package func setHandler(_ handler: EventHandler) {
        logger.start()
        
        // capture
        let db = Firestore.firestore()
        let objectSourceCollectionRef = db.collection(DB.projectSources)
            .document(parent.value)
            .collection(DB.systemSources)
            .document(id.value)
            .collection(DB.objectSources)
        
        // set listener
        guard self.listener == nil else {
            let log = logger.getLog("Firebase 리스너가 이미 등록되어 있습니다.")
            logger.raw.error("\(log)")
            return
        }
        
        // objectSource의 컬렉션
        self.listener = objectSourceCollectionRef
            .addSnapshotListener { snapshot, error in
                guard let snapshot else {
                    let report = logger.getLog("\(error!)")
                    logger.raw.fault("\(report)")
                    return
                }
                
                snapshot.documentChanges.forEach { changed in
                    // get ObjectSource & data
                    let documentId = changed.document.documentID
                    let objectSource = ObjectSource.ID(documentId)
                    let data: ObjectSource.Data
                    do {
                        data = try changed.document.data(as: ObjectSource.Data.self)
                    } catch {
                        let log = logger.getLog("ObjectSource.Data 디코딩 실패 \(documentId)\n\(error)")
                        logger.raw.fault("\(log)")
                        return
                    }
                    
                    let diff = ObjectSourceDiff(
                        id: objectSource,
                        target: data.target,
                        name: data.name,
                        role: data.role)
                    
                    // ObjectSources 컬렉션 이벤트 처리
                    switch changed.type {
                    case .added:
                        // create ObjectSource
                        let objectSourceRef = ObjectSource(id: objectSource)
                        self.objects[diff.target] = objectSourceRef.id
                        
                        handler.execute(.objectAdded(diff))
                        return
                    case .modified:
                        // modify ObjectSource
                        objectSource.ref?.handler?.execute(.modified(diff))
                    case .removed:
                        // remove ObjectSource
                        objectSource.ref?.delete()
                        objectSource.ref?.handler?.execute(.removed(diff))
                        return
                    }
                }
            }
    }
    
    package func notifyNameChanged() async {
        return
    }
    
    
    // MARK: action
    package func addSystemTop() async {
        logger.start()
        
        // mutate
        guard id.isExist else {
            logger.failure("SystemSource가 존재하지 않아 실행 취소됩니다.")
            return
        }
        
        // db & ref
        let firebaseDB = Firestore.firestore()
        
        let projectSourceDocRef = firebaseDB
            .collection(DB.projectSources)
            .document(parent.value)
        
        let systemSourceCollectionRef = firebaseDB
            .collection(DB.projectSources)
            .document(parent.value)
            .collection(DB.systemSources)
        
        let systemSourceDocRef = systemSourceCollectionRef
            .document(id.value)
        
        // transaction
        do {
            let _ = try await firebaseDB.runTransaction { @Sendable transaction, errorPointer in
                do {
                    // get systemSourceData, projectSourceData
                    let systemSourceData = try transaction.getDocument(systemSourceDocRef)
                        .data(as: Data.self)
                    
                    let projectSourceData = try transaction.getDocument(projectSourceDocRef)
                        .data(as: ProjectSource.Data.self)
            
                    // compute topLocation
                    let topLocation = systemSourceData.location.getTop()
                    
                    
                    // check SystemSource(rightLocation) alreadyExist
                    let systemLocations = projectSourceData.systemLocations
                    
                    guard systemLocations.contains(topLocation) == false else {
                        let log = logger.getLog("위쪽에 이미 SystemSource가 존재합니다")
                        logger.raw.error("\(log)")
                        return
                    }
                    
                    // create SystemSource in rightLocation
                    let newSystemSourceDocRef = systemSourceCollectionRef.document()
                    
                    let newSystemSourceData = SystemSource.Data(name: "New System",
                                                                location: topLocation)
                    
                    try transaction.setData(from: newSystemSourceData,
                                            forDocument: newSystemSourceDocRef)
                    
                    // update ProjectSource.systemLocations
                    let newSystemLocations = systemLocations.union([topLocation])
                    
                    transaction.updateData(
                        [ProjectSource.Data.systemLocations: newSystemLocations.encode()],
                        forDocument: projectSourceDocRef
                    )
                    
                } catch {
                    let log = logger.getLog("\(error)")
                    logger.raw.fault("\(log)")
                    return
                }
                
                return
            }
        } catch {
            let log = logger.getLog("\(error)")
            logger.raw.fault("\(log)")
            return
        }
    }
    package func addSystemLeft() async {
        logger.start()
        
        guard id.isExist else {
            logger.failure("SystemSource가 존재하지 않아 실행 취소됩니다.")
            return
        }
        
        // db & ref
        let firebaseDB = Firestore.firestore()
        
        let projectSourceDocRef = firebaseDB
            .collection(DB.projectSources)
            .document(parent.value)
        
        let systemSourceCollectionRef = firebaseDB
            .collection(DB.projectSources)
            .document(parent.value)
            .collection(DB.systemSources)
        
        let systemSourceDocRef = systemSourceCollectionRef
            .document(id.value)
        
        // transaction
        do {
            let _ = try await firebaseDB.runTransaction { @Sendable transaction, errorPointer in
                do {
                    // get systemSourceData, projectSourceData
                    let systemSourceData = try transaction.getDocument(systemSourceDocRef)
                        .data(as: Data.self)
                    
                    let projectSourceData = try transaction.getDocument(projectSourceDocRef)
                        .data(as: ProjectSource.Data.self)
            
                    // compute leftLocation
                    let leftLocation = systemSourceData.location.getLeft()
                    
                    
                    // check SystemSource(rightLocation) alreadyExist
                    let systemLocations = projectSourceData.systemLocations
                    
                    guard systemLocations.contains(leftLocation) == false else {
                        let log = logger.getLog("Left 방향에 이미 SystemSource가 존재합니다")
                        logger.raw.error("\(log)")
                        return
                    }
                    
                    // create SystemSource in rightLocation
                    let newSystemSourceDocRef = systemSourceCollectionRef.document()
                    
                    let newSystemSourceData = SystemSource.Data(name: "New System",
                                                                location: leftLocation)
                    
                    try transaction.setData(from: newSystemSourceData,
                                            forDocument: newSystemSourceDocRef)
                    
                    // update ProjectSource.systemLocations
                    let newSystemLocations = systemLocations.union([leftLocation])
                    
                    transaction.updateData(
                        [ProjectSource.Data.systemLocations: newSystemLocations.encode()],
                        forDocument: projectSourceDocRef
                    )
                    
                } catch {
                    let log = logger.getLog("\(error)")
                    logger.raw.fault("\(log)")
                    return
                }
                
                return
            }
        } catch {
            let log = logger.getLog("\(error)")
            logger.raw.fault("\(log)")
            return
        }
    }
    package func addSystemRight() async {
        logger.start()
        
        guard id.isExist else {
            logger.failure("SystemSource가 존재하지 않아 실행 취소됩니다.")
            return
        }
        
        // db & ref
        let firebaseDB = Firestore.firestore()
        
        let projectSourceDocRef = firebaseDB
            .collection(DB.projectSources)
            .document(parent.value)
        
        let systemSourceCollectionRef = firebaseDB
            .collection(DB.projectSources)
            .document(parent.value)
            .collection(DB.systemSources)
        
        let systemSourceDocRef = systemSourceCollectionRef
            .document(id.value)
        
        // transaction
        do {
            let _ = try await firebaseDB.runTransaction { @Sendable transaction, errorPointer in
                do {
                    // get systemSourceData, projectSourceData
                    let systemSourceData = try transaction.getDocument(systemSourceDocRef)
                        .data(as: Data.self)
                    
                    let projectSourceData = try transaction.getDocument(projectSourceDocRef)
                        .data(as: ProjectSource.Data.self)
            
                    // compute rightLocation
                    let rightLocation = systemSourceData.location.getRight()
                    
                    
                    // check SystemSource(rightLocation) alreadyExist
                    let systemLocations = projectSourceData.systemLocations
                    
                    guard systemLocations.contains(rightLocation) == false else {
                        let log = logger.getLog("Right 방향에 이미 SystemSource가 존재합니다")
                        logger.raw.error("\(log)")
                        return
                    }
                    
                    // create SystemSource in rightLocation
                    let newSystemSourceDocRef = systemSourceCollectionRef.document()
                    
                    let newSystemSourceData = SystemSource.Data(name: "New System",
                                                                location: rightLocation)
                    
                    try transaction.setData(from: newSystemSourceData,
                                            forDocument: newSystemSourceDocRef)
                    
                    // update ProjectSource.systemLocations
                    let newSystemLocations = systemLocations.union([rightLocation])
                    
                    transaction.updateData(
                        [ProjectSource.Data.systemLocations: newSystemLocations.encode()],
                        forDocument: projectSourceDocRef
                    )
                    
                } catch {
                    let log = logger.getLog("\(error)")
                    logger.raw.fault("\(log)")
                    return
                }
                
                return
            }
        } catch {
            let log = logger.getLog("\(error)")
            logger.raw.fault("\(log)")
            return
        }
    }
    package func addSystemBottom() async {
        logger.start()
        
        guard id.isExist else {
            logger.failure("SystemSource가 존재하지 않아 실행 취소됩니다.")
            return
        }
        
        // db & ref
        let firebaseDB = Firestore.firestore()
        
        let projectSourceDocRef = firebaseDB
            .collection(DB.projectSources)
            .document(parent.value)
        
        let systemSourceCollectionRef = firebaseDB
            .collection(DB.projectSources)
            .document(parent.value)
            .collection(DB.systemSources)
        
        let systemSourceDocRef = systemSourceCollectionRef
            .document(id.value)
        
        // transaction
        do {
            let _ = try await firebaseDB.runTransaction { @Sendable transaction, errorPointer in
                do {
                    // get systemSourceData, projectSourceData
                    let systemSourceData = try transaction.getDocument(systemSourceDocRef)
                        .data(as: Data.self)
                    
                    let projectSourceData = try transaction.getDocument(projectSourceDocRef)
                        .data(as: ProjectSource.Data.self)
            
                    // compute bottomLocation
                    let bottomLocation = systemSourceData.location.getBotttom()
                    
                    
                    // check SystemSource(rightLocation) alreadyExist
                    let systemLocations = projectSourceData.systemLocations
                    
                    guard systemLocations.contains(bottomLocation) == false else {
                        let log = logger.getLog("Bottom 방향에 이미 SystemSource가 존재합니다")
                        logger.raw.error("\(log)")
                        return
                    }
                    
                    // create SystemSource in rightLocation
                    let newSystemSourceDocRef = systemSourceCollectionRef.document()
                    
                    let newSystemSourceData = SystemSource.Data(name: "New System",
                                                                location: bottomLocation)
                    
                    try transaction.setData(from: newSystemSourceData,
                                            forDocument: newSystemSourceDocRef)
                    
                    // update ProjectSource.systemLocations
                    let newSystemLocations = systemLocations.union([bottomLocation])
                    
                    transaction.updateData(
                        [ProjectSource.Data.systemLocations: newSystemLocations.encode()],
                        forDocument: projectSourceDocRef
                    )
                    
                } catch {
                    let log = logger.getLog("\(error)")
                    logger.raw.fault("\(log)")
                    return
                }
                
                return
            }
        } catch {
            let log = logger.getLog("\(error)")
            logger.raw.fault("\(log)")
            return
        }
    }
    
    package func removeSystem() async {
        logger.start()
        
        guard id.isExist else {
            logger.failure("SystemSource가 존재하지 않아 실행 취소됩니다.")
            return
        }
        
        // db & docRef
        let firebaseDB = Firestore.firestore()
        let projectSourceDocRef = firebaseDB
            .collection(DB.projectSources)
            .document(parent.value)
        let systemSourceDocRef = projectSourceDocRef
            .collection(DB.systemSources)
            .document(id.value)
        
        do {
            let _ = try await firebaseDB.runTransaction { @Sendable transaction, errorPointer in
                // get SystemSource location
                let location: Location
                do {
                    location = try transaction
                        .getDocument(systemSourceDocRef)
                        .data(as: SystemSource.Data.self)
                        .location
                } catch {
                    let log = logger.getLog("SystemSource 디코딩 실패\n\(error)")
                    logger.raw.fault("\(log)")
                    return
                }
                
                // remove location in ProjectSource.systemLocations
                transaction.updateData([
                    ProjectSource.Data.systemLocations: FieldValue.arrayRemove([location.encode()])
                ], forDocument: projectSourceDocRef)
                
                
                // delete SystemSource
                transaction.deleteDocument(systemSourceDocRef)
                
                return
            }
        } catch {
            let log = logger.getLog("SystemSource Document 삭제 실패\n\(error)")
            logger.raw.error("\(log)")
        }
    }
    
    
    
    // MARK: value
    @MainActor
    package struct ID: SystemSourceIdentity {
        let value: String
        nonisolated init(_ value: String) {
            self.value = value
        }
        
        package var isExist: Bool {
            SystemSourceManager.container[self] != nil
        }
        package var ref: SystemSource? {
            SystemSourceManager.container[self]
        }
    }
    
    @ShowState
    struct Data: Hashable, Codable {
        @DocumentID var id: String?
        var target: SystemID
        var name: String
        
        var location: Location
        var root: ObjectID?
        
        init(id: String? = nil,
             target: SystemID = SystemID(),
             name: String,
             location: Location) {
            self.id = id
            self.target = target
            self.name = name
            self.location = location
        }
    }
    
    package typealias EventHandler = Handler<SystemSourceEvent>
}


// MARK: Object Manager
@MainActor
package final class SystemSourceManager: Sendable {
    // MARK: state
    fileprivate static var container: [SystemSource.ID: SystemSource] = [:]
    fileprivate static func register(_ object: SystemSource) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: SystemSource.ID) {
        container[id] = nil
    }
}
