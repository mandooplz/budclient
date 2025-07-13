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
                        logger.raw.fault("SystemSource 디코딩 실패\n\(error)")
                        return
                    }
                    
                    let diff = SystemSourceDiff(id: systemSource,
                                                target: data.target,
                                                name: data.name,
                                                location: data.location)
                    
                    
                    switch changed.type {
                    case .added:
                        // create SystemSource
                        let systemSourceRef = SystemSource(id: systemSource,
                                                           target: data.target,
                                                           parent: self.id)
                        self.systemSources.insert(systemSourceRef.id)

                        // serve event
                        handler.execute(.added(diff))
                    case .modified:
                        handler.execute(.modified(diff))
                    case .removed:
                        // delete SystemSource
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
    package func createFirstSystem() async throws  {
        // database
        let db = Firestore.firestore()
        
        // reference
        let projectSourceRef = db.collection(ProjectSources.name)
            .document(id.value)
        let systemSourcesRef = projectSourceRef.collection(ProjectSources.SystemSources.name)
        
        // transaction
        do {
            let _ = try await db.runTransaction { @Sendable transaction, errorPointer in
                do {
                    // check ProjectSource.systemModelCoun
                    let data = try transaction.getDocument(projectSourceRef)
                        .data(as: ProjectSource.Data.self)
                    guard data.systemModelCount == 0 else {
                        logger.failure("FirstSystem이 이미 존재합니다.")
                        return
                    }
                    
                    // create SystemSource
                    let newSystemSourceRef = systemSourcesRef.document()
                    let newData = SystemSource.Data(target: SystemID(),
                                                    name: "First System",
                                                    location: .origin,
                                                    updateBy: WorkFlow.id)
                    
                    try transaction.setData(from: newData, forDocument: newSystemSourceRef)
                    
                    
                    // increase ProjectSource.systemModelCount
                    transaction.updateData([
                        "systemModelCount" : FieldValue.increment(Int64(1))
                    ], forDocument: projectSourceRef)
                    
                    return
                } catch(let error as NSError) {
                    logger.failure(error)
                    return nil
                }
            }
        } catch {
            logger.failure("트랜잭션 실패\n\(error)")
            return
        }
    }
    package func remove() {
        logger.start()
        
        guard id.isExist else { return }
        guard let projectHubRef = parent.ref else { return }
        
        // ProjectSource 인스턴스 제거
        projectHubRef.projectSources.remove(self.id)
        self.delete()
        
        // FireStore에서 문서 삭제
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
        package var systemModelCount: Int
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

