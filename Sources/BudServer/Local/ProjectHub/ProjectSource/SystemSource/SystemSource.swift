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

private let logger = BudLogger("SystemSource")


// MARK: Object
@MainActor
package final class SystemSource: SystemSourceInterface {
    // MARK: core
    init(id: ID, target: SystemID, parent: ProjectSource.ID) {
        self.id = id
        self.target = target
        self.owner = parent
        
        SystemSourceManager.register(self)
    }
    func delete() {
        listener?.remove()
        
        SystemSourceManager.unregister(self.id)
    }
    
    
    // MARK: state
    nonisolated let id: ID
    nonisolated let target: SystemID
    nonisolated let owner: ProjectSource.ID
    
    package func setName(_ value: String) {
        logger.start()
        
        // compute
        let db = Firestore.firestore()
        let docRef = db.collection(DB.ProjectSources)
            .document(owner.value)
            .collection(DB.SystemSources)
            .document(id.value)
        
        let updateData: [String: Any] = [
            Data.name : value,
            Data.updatedAt: FieldValue.serverTimestamp()
        ]
        
        docRef.updateData(updateData)
    }
    
    package var objects: [ObjectID: ObjectSource.ID] = [:]
    
    var listener: ListenerRegistration?
    var handler: EventHandler?
    
    package func appendHandler(requester: ObjectID, _ handler: EventHandler) {
        logger.start()
        
        // capture
        let me = self.id
        
        let db = Firestore.firestore()
        let objectSourceCollectionRef = db.collection(DB.ProjectSources)
            .document(owner.value)
            .collection(DB.SystemSources)
            .document(id.value)
            .collection(DB.ObjectSources)
        
        // set listener
        guard self.listener == nil else {
            logger.failure("Firebase 리스너가 이미 등록되어 있습니다.")
            return
        }
        
        // objectSource의 컬렉션
        self.listener = objectSourceCollectionRef
            .addSnapshotListener { snapshot, error in
                guard let snapshot else {
                    logger.failure(error!)
                    return
                }
                
                snapshot.documentChanges.forEach { changed in
                    // get ObjectSource & data
                    let documentId = changed.document.documentID
                    let objectSource = ObjectSource.ID(documentId)
                    
                    let data: ObjectSource.Data
                    let diff: ObjectSourceDiff
                    do {
                        data = try changed.document.data(as: ObjectSource.Data.self)
                        diff = data.getDiff(id: objectSource)
                    } catch {
                        logger.failure("ObjectSource.Data 디코딩 실패 \(documentId)\n\(error)")
                        return
                    }
                    
                    
                    // process event
                    switch changed.type {
                    case .added:
                        // create ObjectSource
                        let objectSourceRef = ObjectSource(
                            id: objectSource,
                            target: diff.target,
                            owner: me)
                        me.ref?.objects[diff.target] = objectSourceRef.id
                        
                        handler.execute(.objectAdded(diff))
                        return
                    case .modified:
                        // modify ObjectSource
                        objectSource.ref?.handler?.execute(.modified(diff))
                    case .removed:
                        // notify
                        objectSource.ref?.handler?.execute(.removed)
                        
                        // remove ObjectSource
                        objectSource.ref?.delete()
                    }
                }
            }
    }
    
    package func registerSync(_ object: ObjectID) async {
        // Firebase에서 자체적으로 처리함
        return
    }
    
    // MARK: action
    package func synchronize() async {
        logger.start()
        
        // Firebase에서 listener를 등록할 때 내부적으로 호출
        
        return
    }
    package func notifyStateChanged() async {
        return
    }
    
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
            .collection(DB.ProjectSources)
            .document(owner.value)
        
        let systemSourceCollectionRef = firebaseDB
            .collection(DB.ProjectSources)
            .document(owner.value)
            .collection(DB.SystemSources)
        
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
                        logger.failure("위쪽에 이미 SystemSource가 존재합니다")
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
                    logger.failure(error)
                    return
                }
                
                return
            }
        } catch {
            logger.failure(error)
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
            .collection(DB.ProjectSources)
            .document(owner.value)
        
        let systemSourceCollectionRef = firebaseDB
            .collection(DB.ProjectSources)
            .document(owner.value)
            .collection(DB.SystemSources)
        
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
                        logger.failure("Left 방향에 이미 SystemSource가 존재합니다")
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
                    logger.failure(error)
                    return
                }
                
                return
            }
        } catch {
            logger.failure(error)
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
            .collection(DB.ProjectSources)
            .document(owner.value)
        
        let systemSourceCollectionRef = firebaseDB
            .collection(DB.ProjectSources)
            .document(owner.value)
            .collection(DB.SystemSources)
        
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
                        logger.failure("Right 방향에 이미 SystemSource가 존재합니다")
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
                    logger.failure(error)
                    return
                }
                
                return
            }
        } catch {
            logger.failure(error)
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
            .collection(DB.ProjectSources)
            .document(owner.value)
        
        let systemSourceCollectionRef = firebaseDB
            .collection(DB.ProjectSources)
            .document(owner.value)
            .collection(DB.SystemSources)
        
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
                        logger.failure("Bottom 방향에 이미 SystemSource가 존재합니다")
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
                    logger.failure(error)
                    return
                }
                
                return
            }
        } catch {
            logger.failure(error)
            return
        }
    }
    
    package func createRootObject() async {
        logger.start()
        
        // capture
        guard id.isExist else {
            logger.failure("SystemSource가 존재하지 않아 실행 취소됩니다.")
            return
        }
        
        // compute
        let firebaseDB = Firestore.firestore()
        
        let systemSourceDocRef = firebaseDB
            .collection(DB.ProjectSources)
            .document(owner.value)
            .collection(DB.SystemSources)
            .document(id.value)
        
        let objectSourceCollectionRef = systemSourceDocRef
            .collection(DB.ObjectSources)
        
        do {
            let _ = try await firebaseDB.runTransaction { @Sendable transaction, errorPointer in
                do {
                    // get SystemSourceData
                    let systemSourceData = try transaction
                        .getDocument(systemSourceDocRef)
                        .data(as: SystemSource.Data.self)
                    
                    // check root exist
                    guard systemSourceData.rootExist == false else {
                        logger.failure("이미 RootObjectSource가 존재합니다.")
                        return
                    }
                    
                    // create ObjectSource
                    let newObjectSourceDocRef = objectSourceCollectionRef
                        .document()
                    
                    let newObjectSourceData = ObjectSource.Data(
                        name: "New Object",
                        role: .root)
                    
                    try transaction.setData(from: newObjectSourceData,
                                            forDocument: newObjectSourceDocRef)
                    
                    
                    // modify SystemSource.root
                    transaction.updateData(
                        [SystemSource.Data.rootExist: true],
                        forDocument: systemSourceDocRef)
                    
                    // return
                    return
                } catch(let error as NSError) {
                    logger.failure(error)
                    return nil
                }
            }
        } catch {
            logger.failure(error)
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
            .collection(DB.ProjectSources)
            .document(owner.value)
        let systemSourceDocRef = projectSourceDocRef
            .collection(DB.SystemSources)
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
                    logger.failure("SystemSource 디코딩 실패\n\(error)")
                    return
                }
                
                // cancel location in ProjectSource.systemLocations
                transaction.updateData([
                    ProjectSource.Data.systemLocations: FieldValue.arrayRemove([location.encode()])
                ], forDocument: projectSourceDocRef)
                
                
                // delete SystemSource
                transaction.deleteDocument(systemSourceDocRef)
                
                return
            }
        } catch {
            logger.failure("SystemSource Document 삭제 실패\n\(error)")
            return
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
        
        @ServerTimestamp var createdAt: Timestamp?
        @ServerTimestamp var updatedAt: Timestamp?
        var order: Int
        
        var name: String
        var location: Location
        var rootExist: Bool = false
        
        init(order: Int = 0,
             name: String,
             location: Location) {
            self.order = order
            self.target = SystemID()
            self.name = name
            self.location = location
        }
        
        func getDiff(id: SystemSource.ID) -> SystemSourceDiff {
            let now = Date.now
            
            return .init(id: id,
                         target: self.target,
                         createdAt: self.createdAt?.dateValue() ?? now,
                         updatedAt: self.updatedAt?.dateValue() ?? now,
                         order: self.order,
                         name: self.name,
                         location: self.location)
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
