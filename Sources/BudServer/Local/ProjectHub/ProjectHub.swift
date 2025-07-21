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
    
    var listener: ListenerRegistration?
    var handlers: [ObjectID:EventHandler] = [:]
    package func appendHandler(for requester: ObjectID, _ handler: EventHandler) {
        // capture
        let projectHub = self.id
        
        self.handlers[requester] = handler
        
        // mutate - firebase
        guard self.listener == nil else {
            logger.failure("Firebase 리스너가 이미 등록되어 있습니다.")
            return
        }
        
        let db = Firestore.firestore()
        let projectSourcesCollectionRef = db.collection(DB.ProjectSources)
            .whereField(ProjectSource.Data.creator, isEqualTo: user.encode())
        
        self.listener = projectSourcesCollectionRef
            .addSnapshotListener { snapshot, error in
                guard let snapshot else {
                    logger.failure(error!)
                    return
                }
                
                snapshot.documentChanges.forEach { diff in
                    let documentId = diff.document.documentID
                    let projectSource = ProjectSource.ID(documentId)
                    
                    let data: ProjectSource.Data
                    do {
                        data = try diff.document.data(as: ProjectSource.Data.self)
                    } catch {
                        logger.failure("ProjetSource 디코딩 실패\n\(error)")
                        return
                    }
                    
                    switch diff.type {
                    case .added:
                        // create ProjectSource
                        let projectSourceRef = ProjectSource(id: projectSource,
                                                             name: data.name,
                                                             target: data.target,
                                                             parent: self.id)
                        self.projectSources[data.target] = projectSourceRef.id
                        
                        // serve event
                        let diff = ProjectSourceDiff(id: projectSource,
                                                     target: projectSourceRef.target,
                                                     name: data.name)
                        
                        projectHub.ref?.handlers.values.forEach { eventHandler in
                            eventHandler.execute(.added(diff))
                        }
                    case .modified:
                        // serve event
                        guard let projectSourceRef = projectSource.ref else {
                            logger.failure("ProjectSource가 존재하지 않아 update가 취소되었습니다.")
                            return
                        }
                        
                        let projectSourceHandlers = projectSourceRef.handlers.values
                        let projectSourceDiff = ProjectSourceDiff(id: projectSource,
                                                     target: data.target,
                                                     name: data.name)
                        
                        // modify ProjectSource
                        projectSourceRef.name = data.name
                        projectSourceHandlers.forEach { eventHandler in
                            eventHandler.execute(.modified(projectSourceDiff))
                        }
                    case .removed:
                        guard let projectSourceRef = projectSource.ref else {
                            logger.failure("ProjectSource가 존재하지 않아 update가 취소되었습니다.")
                            return
                        }
                        
                        // serve event
                        let projectSourceHandlers = projectSourceRef.handlers.values
                        
                        projectSourceHandlers.forEach { eventHandler in
                            eventHandler.execute(.removed)
                        }

                        
                        // cancel ProjectSource
                        projectSourceRef.delete()
                        self.projectSources[data.target] = nil
                    }
                }
            }
    }
    package func removeHandler(of requester: ObjectID) async {
        logger.start()
        
        guard id.isExist else {
            logger.failure("ProjectHub가 존재하지 않아 실행 취소됩니다.")
            return
        }
        
        self.handlers[requester] = nil
        
        self.listener?.remove()
        self.listener = nil
    }
    package func synchronize(requester: ObjectID) async {
        logger.start()
        
        // Firebase에서 알아서 호출해준다.
    }
    
    package func notifyNameChanged(_ project: ProjectID) async {
        return
    }
    
    // MARK: action
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

