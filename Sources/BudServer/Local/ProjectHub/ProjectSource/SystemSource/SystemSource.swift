//
//  SystemSource.swift
//  BudClient
//
//  Created by 김민우 on 7/7/25.
//
import Foundation
import Values
import FirebaseFirestore

private let logger = WorkFlow.getLogger(for: "SystemSource")


// MARK: Object
@MainActor
package final class SystemSource: SystemSourceInterface {
    // MARK: core
    init(id: ID,
         target: SystemID,
         parent: ProjectSource.ID,
         rootSourceRef: RootSource) {
        self.id = id
        self.target = target
        self.parent = parent
        self.rootSourceRef = rootSourceRef
        
        SystemSourceManager.register(self)
    }
    func delete() {
        SystemSourceManager.unregister(self.id)
    }
    
    
    // MARK: state
    nonisolated let id: ID
    nonisolated let target: SystemID
    nonisolated let parent: ProjectSource.ID
    package nonisolated let rootSourceRef: RootSource
    
    package func setName(_ value: String) {
        logger.start()
        
        // compute
        let db = Firestore.firestore()
        let docRef = db.collection(ProjectSources.name)
            .document(parent.value)
            .collection(ProjectSources.SystemSources.name)
            .document(id.value)
        
        let updateData: [String: Any] = [
            "name": value
        ]
        
        docRef.updateData(updateData)
    }
    
    private var listeners: [ObjectID: ListenerRegistration] = [:]
    package func hasHandler(requester: ObjectID) -> Bool {
        listeners[requester] != nil
    }
    package func setHandler(requester: ObjectID, handler: Handler<SystemSourceEvent>) {
        logger.start()
        
        let db = Firestore.firestore()
        
        // objectSource listener
        self.listeners[requester] = db.collection(ProjectSources.name)
            .document(parent.value)
            .collection(ProjectSources.SystemSources.name)
            .document(id.value)
            .collection(ProjectSources.SystemSources.ObjectSources.name)
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
                        let log = logger.getLog("ObjectSource.Data 디코딩 실패\n\(error)")
                        logger.raw.fault("\(log)")
                        return
                    }
                    
                    let diff = ObjectSourceDiff(
                        id: objectSource,
                        target: data.target,
                        name: data.name)
                    
                    // ObjectSources 컬렉션 이벤트 처리
                    switch changed.type {
                    case .added:
                        // create ObjectSource
                        let _ = ObjectSource(id: objectSource)
                        
                        handler.execute(.added(diff))
                        return
                    case .modified:
                        // modify ObjectSource
                        handler.execute(.modified(diff))
                        return
                    case .removed:
                        // remove ObjectSource
                        objectSource.ref?.delete()
                        
                        handler.execute(.removed(diff))
                        return
                    }
                }
            }
    }
    package func removeHandler(requester: ObjectID) {
        listeners[requester]?.remove()
        listeners[requester] = nil
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
        let db = Firestore.firestore()
        let projectSourceDocument = db.collection(ProjectSources.name)
            .document(parent.value)
        let systemSourceCollection = db.collection(ProjectSources.name)
            .document(parent.value)
            .collection(ProjectSources.SystemSources.name)
        
        let systemSourceRef = systemSourceCollection.document(id.value)
        
        // transaction
        do {
            let _ = try await db.runTransaction { @Sendable transaction, errorPointer in
                do {
                    // get systemSourceData, projectSourceData
                    let systemSourceData = try transaction.getDocument(systemSourceRef)
                        .data(as: Data.self)
                    
                    let projectSourceData = try transaction.getDocument(projectSourceDocument)
                        .data(as: ProjectSource.Data.self)
            
                    // get rightLocation
                    let rightLocation = systemSourceData.location.getRight()
                    
                    
                    // check SystemSource(rightLocation) alreadyExist
                    let systemLocations = projectSourceData.systemLocations
                    guard systemLocations.contains(rightLocation) == false else {
                        let log = logger.getLog("Top 방향에 이미 SystemSource가 존재합니다")
                        logger.raw.error("\(log)")
                        return
                    }
                    
                    // create SystemSource in rightLocation
                    let newSystemSourceDoc = systemSourceCollection.document()
                    
                    let newSystemSourceData = SystemSource.Data(name: "New System",
                                                                location: rightLocation)
                    
                    try transaction.setData(from: newSystemSourceData,
                                            forDocument: newSystemSourceDoc)
                    
                    // update ProjectSource.systemLocations
                    let newSystemLocations = systemLocations.union([rightLocation])
                    
                    transaction.updateData(
                        ["systemLocations": newSystemLocations.encode()],
                        forDocument: projectSourceDocument
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
        
        logger.failure("미구현")
    }
    package func addSystemRight() async {
        logger.start()
        
        guard id.isExist else {
            logger.failure("SystemSource가 존재하지 않아 실행 취소됩니다.")
            return
        }
        
        logger.failure("미구현")
    }
    package func addSystemBottom() async {
        logger.start()
        
        guard id.isExist else {
            logger.failure("SystemSource가 존재하지 않아 실행 취소됩니다.")
            return
        }
        
        logger.failure("미구현")
    }
    
    package func createNewObject() async {
        logger.start()
        
        guard id.isExist else {
            logger.failure("SystemSource가 존재하지 않아 실행 취소됩니다.")
            return
        }
        
        logger.failure("미구현")
    }
    
    package func remove() async {
        logger.start()
        
        guard id.isExist else {
            logger.failure("SystemSource가 존재하지 않아 실행 취소됩니다.")
            return
        }
        
        logger.failure("미구현")
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
    struct Data: Hashable, Codable {
        @DocumentID var id: String?
        var target: SystemID
        var name: String
        var location: Location
        
        var rootSource: RootSource
        
        struct RootSource: Hashable, Codable {
            let id: String
            let target: ObjectID
            let name: String
            
            init(name: String) {
                self.id = UUID().uuidString
                self.target = ObjectID()
                self.name = name
            }
        }
        
        init(id: String? = nil,
             target: SystemID = SystemID(),
             name: String,
             location: Location) {
            self.id = id
            self.target = target
            self.name = name
            self.location = location
            self.rootSource = RootSource(name: name)
        }
    }
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
