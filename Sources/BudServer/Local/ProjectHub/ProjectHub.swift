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
        let workflow = WorkFlow.id
        
        let db = Firestore.firestore()
        self.listeners[requester] = db.collection(ProjectSources.name)
            .whereField("creator",
                        isEqualTo: user.encode())
            .addSnapshotListener { snapshot, error in
                guard let snapshot else {
                    logger.critical(error!)
                    return
                }
                
                let isSourcesEmpty = self.projectSources.isEmpty
                
                snapshot.documentChanges.forEach { diff in
                    let documentId = diff.document.documentID
                    let projectSource = ProjectSource.ID(documentId)
                    
                    let data: ProjectSource.Data
                    do {
                        data = try diff.document.data(as: ProjectSource.Data.self)
                    } catch {
                        logger.critical("ProjectSource 디코딩 실패\n\(error)")
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
                        
                        handler.execute(.added(diff), isSourcesEmpty ? workflow : data.createBy)
                    case .modified:
                        // serve event
                        let diff = ProjectSourceDiff(id: projectSource,
                                                      target: data.target,
                                                      name: data.name)
                        
                        handler.execute(.modified(diff), data.updateBy!)
                    case .removed:
                        // remove ProjectSource
                        projectSource.ref?.delete()
                        self.projectSources.remove(projectSource)
                        
                        // serve event
                        let diff = ProjectSourceDiff(id: projectSource,
                                                     target: data.target,
                                                     name: data.name)
                        
                        handler.execute(.removed(diff), data.removedBy!)
                    }
                }
            }
    }
    package func removeHandler(requester: ObjectID) {
        self.listeners[requester]?.remove()
        self.listeners[requester] = nil
    }
    
    package func notifyNameChanged(_ project: ProjectID) async {
        return
    }
    
    // MARK: action
    package func createNewProject() throws {
        logger.start()
        
        let db = Firestore.firestore()
        let workflow = WorkFlow.id
        
        while tickets.isEmpty == false {
            let ticket = tickets.removeFirst()
            
            // create ProjectSource in Firestore
            let data = ProjectSource.Data(name: ticket.name,
                                          creator: ticket.creator,
                                          target: ticket.target,
                                          systemModelCount: 0,
                                          createBy: workflow,
                                          updateBy: nil,
                                          removedBy: nil)
            
            try db.collection(ProjectSources.name).addDocument(from: data)
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

