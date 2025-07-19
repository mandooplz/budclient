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
import BudMacro

private let logger = BudLogger("ProjectSource")


// MARK: Object
@MainActor
package final class ProjectSource: ProjectSourceInterface {
    // MARK: core
    init(id: ID, name: String, target: ProjectID, parent: ProjectHub.ID) {
        self.id = id
        self.target = target
        self.parent = parent
        
        self.name = name
        
        ProjectSourceManager.register(self)
    }
    func delete() {
        self.listener?.remove()
        
        ProjectSourceManager.unregister(self.id)
    }
    
    // MARK: state
    package nonisolated let id: ID
    nonisolated let target: ProjectID
    nonisolated let parent: ProjectHub.ID
    
    var systemSources: [SystemID: SystemSource.ID] = [:]
    
    var name: String
    package func setName(_ value: String) {
        logger.start(value)
        
        // set ProjectSource.name
        let db = Firestore.firestore()
        let docRef = db.collection(DB.projectSources).document(id.value)
        
        let updateData: [String: Any] = [
            ProjectSource.Data.name: value
        ]
        
        docRef.updateData(updateData)
    }
    
    // objectID마다 있어야 하는가?
    package var listener: ListenerRegistration?
    package var handler: EventHandler?
    package func setHandler(_ handler: EventHandler) {
        logger.start()
        
        let db = Firestore.firestore()
        let systemSourceCollectionRef = db.collection(DB.projectSources)
            .document(id.value)
            .collection(DB.systemSources)
        
        self.handler = handler
        
        guard self.listener == nil else {
            logger.failure("Firebase 리스너가 이미 등록되어 있습니다.")
            return
        }
        
        self.listener = systemSourceCollectionRef
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
                        let log = logger.getLog("SystemSource 디코딩 실패 \(documentId)\n\(error)")
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
                        let systemSourceRef = SystemSource(id: systemSource,
                                                           target: data.target,
                                                           parent: self.id)
                        
                        self.systemSources[data.target] = systemSourceRef.id

                        // serve event
                        handler.execute(.added(diff))
                    case .modified:
                        guard let systemSourceRef = systemSource.ref else {
                            logger.failure("SystemSource가 존재하지 않아 실행 취소됩니다.")
                            return
                        }
                        
                        systemSourceRef.handler?.execute(.modified(diff))
                    case .removed:
                        guard let systemSourceRef = systemSource.ref else {
                            logger.failure("SystemSource가 존재하지 않아 실행 취소됩니다.")
                            return
                        }
                        
                        systemSourceRef.handler?.execute(.removed)
                        
                        // delete SystemSource
                        self.systemSources[data.target] = nil
                        systemSource.ref?.delete()
                    }
                }
            })
    }
    
    package func notifyNameChanged() async {
        return
    }
    
    
    // MARK: action
    package func createSystem() async  {
        logger.start()
        
        guard id.isExist else {
            logger.failure("ProjectSource가 존재하지 않아 실행 취소됩니다.")
            return
        }
        
        // database
        let firebaseDB = Firestore.firestore()
        
        // get ref
        let projectSourceDocRef = firebaseDB
            .collection(DB.projectSources)
            .document(id.value)
        
        let systemSourceCollectionRef = projectSourceDocRef
            .collection(DB.systemSources)
        
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
                        Data.systemLocations : newSystemLocationSet.encode()
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
    package func removeProject() {
        logger.start()
        
        guard id.isExist else {
            logger.failure("ProjectSource가 존재하지 않아 실행 취소됩니다.")
            return
        }
        let projectHubRef = parent.ref!
        
        // delete ProjectSource
        projectHubRef.projectSources[target] = nil
        self.delete()
        
        // remove ProjectSourceDocument in FireStore
        let db = Firestore.firestore()
        db.collection(DB.projectSources)
            .document(id.value)
            .delete()
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
    
    @ShowState
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
    package typealias EventHandler = Handler<ProjectSourceEvent>
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

