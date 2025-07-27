//
//  ProjectHub.swift
//  BudClient
//
//  Created by 김민우 on 6/30/25.
//
import Foundation
import Values
import Collections
import FirebaseFirestore

private let logger = BudLogger("ProjectHub")


// MARK: Object
@MainActor
package final class ProjectHub: ProjectHubInterface {
    // MARK: core
    init(user: UserID) {
        self.user = user
        
        ProjectHubManager.register(self)
    }
    
    
    // MARK: state
    package nonisolated let id = ID()
    nonisolated let user: UserID
    
    var projectSources: [ProjectID: ProjectSource.ID] = [:]
    
    package func registerSync(_ object: ObjectID) async {
        // Firebase에서 자체적으로 처리
        return
    }
    
    var listener: ListenerRegistration?
    var handler: EventHandler?
    package func appendHandler(requester: ObjectID,
                               _ handler: EventHandler) {
        // capture
        guard self.listener == nil else {
            logger.failure("ProjectSource의 Firebase 리스너가 이미 등록되어 있습니다.")
            return
        }
        let me = self.id
        
        // compute
        let db = Firestore.firestore()
        let projectSourcesCollectionRef = db
            .collection(DB.ProjectSources)
            .whereField(ProjectSource.Data.creator, isEqualTo: user.encode())
        
        let projectListener = projectSourcesCollectionRef
            .addSnapshotListener { snapshot, error in
                guard let snapshot else {
                    logger.failure(error!)
                    return
                }
                
                snapshot.documentChanges.forEach { change in
                    // get ProjectSource
                    let documentId = change.document.documentID
                    let projectSource = ProjectSource.ID(documentId)
                    
                    let data: ProjectSource.Data
                    do {
                        data = try change.document.data(as: ProjectSource.Data.self)
                    } catch {
                        logger.failure("ProjetSource 디코딩 실패\n\(error)")
                        return
                    }
                    
                    guard let createdAt = data.createdAt?.dateValue(),
                          let updatedAt = data.updatedAt?.dateValue() else {
                        logger.failure("ProjectSource의 createdAt, updatedAt이 nil입니다.")
                        return
                    }
                    
                    let diff = ProjectSourceDiff(
                        id: projectSource,
                        target: data.target,
                        name: data.name,
                        createdAt: createdAt,
                        updatedAt: updatedAt,
                        order: data.order
                    )
                    
                    switch change.type {
                    case .added:
                        // create ProjectSource
                        let projectSourceRef = ProjectSource(id: projectSource,
                                                             target: data.target,
                                                             owner: me)
                        me.ref?.projectSources[data.target] = projectSourceRef.id
                        
                        me.ref?.handler?.execute(.added(diff))
                    case .modified:
                        // notify
                        projectSource.ref?.handlers?.execute(.modified(diff))
                    case .removed:
                        guard let projectSourceRef = projectSource.ref else {
                            logger.failure("ProjectSource가 존재하지 않아 update가 취소되었습니다.")
                            return
                        }
                        
                        // remove ProjectSource
                        projectSourceRef.delete()
                        me.ref?.projectSources[data.target] = nil
                        
                        // notify
                        projectSource.ref?.handlers?.execute(.removed)
                    }
                }
            }
        
        // mutate
        self.handler = handler
        self.listener = projectListener
    }
    
    package func notifyNameChanged(_ project: ProjectID) async {
        logger.start()
        
        logger.failure("Firebase에서 알아서 처리됨")
    }
    
    // MARK: action
    package func synchronize() async {
        logger.start()
        
        logger.failure("Firebase에서 알아서 처리됨")
    }
    
    package func createProject() {
        logger.start()
        
        let db = Firestore.firestore()
        
        do {
            let newProjectName = "Project \(Int.random(in: 1..<1000))"
            
            // create ProjectSource in Firestore
            let data = ProjectSource.Data(name: newProjectName,
                                          creator: self.user)
            
            try db.collection(DB.ProjectSources)
                .addDocument(from: data)
        } catch {
            logger.failure(error)
            return
        }
    }
    
    
    // MARK: value
    @MainActor
    package struct ID: ProjectHubIdentity {
        let value: UUID = UUID()
        nonisolated init() { }
        
        package var isExist: Bool {
            ProjectHubManager.container[self] != nil
        }
        package var ref: ProjectHub? {
            ProjectHubManager.container[self]
        }
    }
    
    package typealias EventHandler = Handler<ProjectHubEvent>
}


// MARK: ObjectManager
@MainActor
fileprivate final class ProjectHubManager: Sendable {
    // MARK: state
    fileprivate static var container: [ProjectHub.ID: ProjectHub] = [:]
    fileprivate static func register(_ object: ProjectHub) {
        container[object.id] = object
    }
}

