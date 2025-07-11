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

private nonisolated let logger = WorkFlow.getLogger(for: "ProjectSource")


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
        // set ProjectSource.name
        let db = Firestore.firestore()
        let docRef = db.collection(ProjectSources.name).document(id.value)
        
        let updateData: [String: Any] = [
            "name": value,
            "metadata": [
                "update": [
                    "value": WorkFlow.id.value?.uuidString
                ]
            ]
        ]
        
        docRef.updateData(updateData)
        logger.success(value)
    }
    
    package var listeners: [ObjectID: ListenerRegistration] = [:]
    
    package func hasHandler(requester: ObjectID) -> Bool {
        self.listeners[requester] != nil
    }
    package func setHandler(requester: ObjectID, handler: Handler<ProjectSourceEvent>) {
        // 중복 방지
        guard self.listeners[requester] == nil else { return }
        let workflow = WorkFlow.id
        
        let db = Firestore.firestore()
        self.listeners[requester] = db.collection(ProjectSources.name)
            .document(id.value)
            .collection(ProjectSources.SystemSources.name)
            .addSnapshotListener({ snapshot, error in
                guard let snapshot else {
                    logger.failure(error?.localizedDescription ?? "Snapshot Error")
                    return
                }
                
                snapshot.documentChanges.forEach { changed in
                    let documentId = changed.document.documentID
                    let systemSource = SystemSource.ID(documentId)
                    
                    guard let data = try? changed.document.data(as: SystemSource.Data.self) else {
                        logger.failure("SystemSource.Data Decoding 실패")
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
                        handler.execute(.added(diff), data.updateBy)
                    case .modified:
                        handler.execute(.modified(diff), data.updateBy)
                    case .removed:
                        // delete SystemSource
                        systemSource.ref?.delete()
                        
                        // serve event
                        handler.execute(.removed(diff), data.updateBy)
                    }
                }
            })
    }
    package func removeHandler(requester: ObjectID) {
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
        let _ = try await db.runTransaction { @Sendable transaction, errorPointer in
            do {
                // check ProjectSource.systemModelCount
                let data = try transaction.getDocument(projectSourceRef)
                    .data(as: ProjectSource.Data.self)
                guard data.systemModelCount == 0 else {
                    return nil
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
                    ProjectSource.State.systemModelCount: FieldValue.increment(Int64(1))
                ], forDocument: projectSourceRef)
                
                return
            } catch(let error as NSError) {
                errorPointer?.pointee = error
                return nil
            }
        }
    }
    package func remove() {
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
        package var metadata: MetaData
        
        package struct MetaData: Sendable, Hashable, Codable {
            package let create: WorkFlow.ID
            package let update: WorkFlow.ID?
            package let remove: WorkFlow.ID?
        }
    }
    enum State: String, Sendable {
        case name
        case creator
        case target
        case systemModelCount
        case updateBy
        
        static func getSystemModelCountUpdater(_ value: Int) -> [String: Any] {
            [State.systemModelCount.rawValue: value]
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

