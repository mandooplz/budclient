//
//  ProjectSource.swift
//  BudClient
//
//  Created by 김민우 on 7/3/25.
//
import Foundation
import Values
import Collections
import FirebaseFirestore

private let logger = WorkFlow.getLogger(for: "ProjectSource")


// MARK: Object
@MainActor
package final class ProjectSource: ProjectSourceInterface {
    // MARK: core
    init(id: ID, target: ProjectID, parent: ProjectHub.ID) {
        self.id = id
        self.target = target
        self.parent = parent
        
        ProjectSourceManager.register(self)
    }
    func delete() {
        ProjectSourceManager.unregister(self.id)
    }
    
    // MARK: state
    package nonisolated let id: ID
    nonisolated let target: ProjectID
    nonisolated let parent: ProjectHub.ID
    
    var systemSources: Set<SystemSource.ID> = []
    
    package func setName(_ value: String) {
        logger.start(value)
        
        // set ProjectSource.name
        let db = Firestore.firestore()
        let docRef = db.collection(ProjectSources.name).document(id.value)
        
        let updateData: [String: Any] = [
            "name": value
        ]
        
        docRef.updateData(updateData)
    }
    
    package var listeners: [ObjectID: ListenerRegistration] = [:]
    
    package func hasHandler(requester: ObjectID) -> Bool {
        self.listeners[requester] != nil
    }
    package func setHandler(requester: ObjectID, handler: Handler<ProjectSourceEvent>) {
        logger.start()
        
        // 중복 방지
        guard self.listeners[requester] == nil else { return }
        
        let db = Firestore.firestore()
        self.listeners[requester] = db.collection(ProjectSources.name)
            .document(id.value)
            .collection(ProjectSources.SystemSources.name)
            .addSnapshotListener({ snapshot, error in
                guard let snapshot else {
                    let log = logger.getLog("\(error!)")
                    logger.raw.fault("\(log)")
                    return
                }
                
                snapshot.documentChanges.forEach { changed in
                    let documentId = changed.document.documentID
                    let systemSource = SystemSource.ID(documentId)
                    
                    let data: SystemSource.Data
                    do {
                        data = try changed.document.data(as: SystemSource.Data.self)
                    } catch {
                        let log = logger.getLog("SystemSource 디코딩 실패\n\(error)")
                        logger.raw.fault("\(log)")
                        return
                    }
                    
                    guard let diff = SystemSourceDiff(from: data) else {
                        let log = logger.getLog("SystemSourceDiff 변환 실패")
                        logger.raw.fault("\(log)")
                        return
                    }
                    
                    
                    switch changed.type {
                    case .added:
                        // create SystemSource
                        let rootSource = RootSource.ID(data.rootSource.id)
                        let rootSourceRef = RootSource(id: rootSource)
                        
                        let systemSourceRef = SystemSource(id: systemSource,
                                                           target: data.target,
                                                           parent: self.id,
                                                           rootSourceRef: rootSourceRef)
                        self.systemSources.insert(systemSourceRef.id)

                        // serve event
                        handler.execute(.added(diff))
                    case .modified:
                        handler.execute(.modified(diff))
                    case .removed:
                        // delete SystemSource
                        self.systemSources.remove(systemSource)
                        systemSource.ref?.delete()
                        
                        // serve event
                        handler.execute(.removed(diff))
                    }
                }
            })
    }
    package func removeHandler(requester: ObjectID) {
        logger.start()
        
        listeners[requester]?.remove()
        listeners[requester] = nil
    }
    
    
    // MARK: action
    package func createFirstSystem() async  {
        logger.start()
        
        guard id.isExist else {
            logger.failure("ProjectSource가 존재하지 않아 실행 취소됩니다.")
            return
        }
        
        // database
        let firebaseDB = Firestore.firestore()
        
        // get ref
        let projectSourceDocRef = firebaseDB
            .collection(ProjectSources.name)
            .document(id.value)
        
        let systemSourceCollectionRef = projectSourceDocRef
            .collection(ProjectSources.SystemSources.name)
        
        // transaction
        do {
            let _ = try await firebaseDB.runTransaction { @Sendable transaction, errorPointer in
                do {
                    // get ProjectSource.Data
                    let projectSourceData = try transaction
                        .getDocument(projectSourceDocRef)
                        .data(as: Data.self)
                    
                    // check System alreadyExist
                    guard projectSourceData.systemLocations.isEmpty else {
                        let log = logger.getLog("(0,0) 위치에 첫 번째 System이 이미 존재합니다.")
                        logger.raw.error("\(log)")
                        return
                    }
                    
                    // create SystemSource
                    let newSystemSourceDocRef = systemSourceCollectionRef
                        .document()
                    
                    let newSystemSourceData = SystemSource.Data(name: "First System",
                                                                location: .origin)
                    
                    try transaction.setData(from: newSystemSourceData,
                                            forDocument: newSystemSourceDocRef)
                    
                    
                    // update ProjectSource.systemLocations
                    let newSystemLocationSet: Set<Location> = [newSystemSourceData.location]
                    
                    transaction.updateData([
                        "systemLocations" : newSystemLocationSet.encode()
                    ], forDocument: projectSourceDocRef)
                    
                    return
                } catch(let error as NSError) {
                    let log = logger.getLog("\(error)")
                    logger.raw.fault("\(log)")
                    return nil
                }
            }
        } catch {
            let log = logger.getLog("트랜잭션 실패\n\(error)")
            logger.raw.fault("\(log)")
            return
        }
    }
    package func remove() {
        logger.start()
        
        guard id.isExist else {
            logger.failure("ProjectSource가 존재하지 않아 실행 취소됩니다.")
            return
        }
        let projectHubRef = parent.ref!
        
        // delete ProjectSource
        projectHubRef.projectSources.remove(self.id)
        self.delete()
        
        // remove ProjectSourceDocument in FireStore
        let db = Firestore.firestore()
        db.collection(ProjectSources.name).document(id.value).delete()
    }
    
    
    // MARK: value
    @MainActor
    package struct ID: ProjectSourceIdentity {
        let value: String
        nonisolated init(_ value: String) {
            self.value = value
        }
        
        package var isExist: Bool {
            ProjectSourceManager.container[self] != nil
        }
        package var ref: ProjectSource? {
            ProjectSourceManager.container[self]
        }
    }
    struct Data: Hashable, Codable {
        @DocumentID var id: String?
        package var name: String
        package var creator: UserID
        package var target: ProjectID
        
        package var systemLocations: Set<Location>
        
        init(name: String, creator: UserID) {
            self.name = name
            self.creator = creator
            self.target = ProjectID()
            self.systemLocations = []
        }
    }
}


// MARK: Object Manager
@MainActor
fileprivate final class ProjectSourceManager: Sendable {
    fileprivate static var container: [ProjectSource.ID : ProjectSource] = [:]
    fileprivate static func register(_ object: ProjectSource) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: ProjectSource.ID) {
        container[id] = nil
    }
}

