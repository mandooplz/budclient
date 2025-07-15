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

private let logger = WorkFlow.getLogger(for: "ProjectHub")


// MARK: Object
@MainActor
package final class ProjectHub: ProjectHubInterface {
    // MARK: core
    init() {
        ProjectHubManager.register(self)
    }
    
    
    // MARK: state
    package nonisolated let id = ID()
    
    var projectSources: Set<ProjectSource.ID> = []
    
    private var tickets: Deque<CreateProject> = []
    package func insertTicket(_ ticket: CreateProject) async {
        tickets.append(ticket)
    }
    
    private var listeners: [ObjectID:ListenerRegistration] = [:]
    package func hasHandler(requester: ObjectID) async -> Bool {
        listeners[requester] != nil
    }
    
    package func setHandler(requester: ObjectID,
                            user: UserID,
                            handler: Handler<ProjectHubEvent>) {
        guard listeners[requester] == nil else { return }
        
        let db = Firestore.firestore()
        self.listeners[requester] = db.collection(DB.projectSources)
            .whereField(ProjectSource.Data.creator,
                        isEqualTo: user.encode())
            .addSnapshotListener { snapshot, error in
                guard let snapshot else {
                    let log = logger.getLog("\(error!)")
                    logger.raw.fault("\(log)")
                    return
                }
                
                snapshot.documentChanges.forEach { diff in
                    let documentId = diff.document.documentID
                    let projectSource = ProjectSource.ID(documentId)
                    
                    let data: ProjectSource.Data
                    do {
                        data = try diff.document.data(as: ProjectSource.Data.self)
                    } catch {
                        let log = logger.getLog("ProjetSource 디코딩 실패\n\(error)")
                        logger.raw.fault("\(log)")
                        return
                    }
                    
                    switch diff.type {
                    case .added:
                        // create ProjectSource
                        let projectSourceRef = ProjectSource(id: projectSource,
                                                             target: data.target,
                                                             parent: self.id)
                        self.projectSources.insert(projectSourceRef.id)
                        
                        // serve event
                        let diff = ProjectSourceDiff(id: projectSource,
                                                     target: projectSourceRef.target,
                                                     name: data.name)
                        
                        handler.execute(.added(diff))
                    case .modified:
                        // serve event
                        let diff = ProjectSourceDiff(id: projectSource,
                                                      target: data.target,
                                                      name: data.name)
                        
                        handler.execute(.modified(diff))
                    case .removed:
                        // remove ProjectSource
                        projectSource.ref?.delete()
                        self.projectSources.remove(projectSource)
                        
                        // serve event
                        let diff = ProjectSourceDiff(id: projectSource,
                                                     target: data.target,
                                                     name: data.name)
                        
                        handler.execute(.removed(diff))
                    }
                }
            }
    }
    package func removeHandler(requester: ObjectID) {
        logger.start()
        
        self.listeners[requester]?.remove()
        self.listeners[requester] = nil
    }
    
    package func notifyNameChanged(_ project: ProjectID) async {
        return
    }
    
    // MARK: action
    package func createNewProject() {
        logger.start()
        
        let db = Firestore.firestore()
        
        do {
            while tickets.isEmpty == false {
                let ticket = tickets.removeFirst()
                
                let newProjectName = "Project \(Int.random(in: 1..<1000))"
                
                // create ProjectSource in Firestore
                let data = ProjectSource.Data(name: newProjectName,
                                              creator: ticket.creator)
                
                try db.collection(DB.projectSources)
                    .addDocument(from: data)
            }
        } catch {
            let log = logger.getLog(error)
            logger.raw.error("\(log)")
        }
    }
    
    
    // MARK: value
    @MainActor
    package struct ID: ProjectHubIdentity {
        let value: String = "ProjectHub"
        nonisolated init() { }
        
        package var isExist: Bool {
            ProjectHubManager.container[self] != nil
        }
        package var ref: ProjectHub? {
            ProjectHubManager.container[self]
        }
    }
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

