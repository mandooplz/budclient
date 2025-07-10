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
import os


// MARK: Object
@MainActor
package final class ProjectHub: Sendable {
    // MARK: core
    package static let shared = ProjectHub()
    private init() { }
    
    
    // MARK: state
    package nonisolated let id = ID()
    private let db = Firestore.firestore()
    
    package var projectSources: Set<ProjectSourceID> = []
    
    package var tickets: Deque<CreateProjectSource> = []
    
    package var listeners: [ObjectID:ListenerRegistration] = [:]
    package func hasHandler(requester: ObjectID) async -> Bool {
        listeners[requester] != nil
    }
    
    package func setHandler(requester: ObjectID, user: UserID, handler: Handler<ProjectHubEvent>) {
        guard listeners[requester] == nil else { return }
        
        self.listeners[requester] = db.collection(ProjectSources.name)
            .whereField(ProjectSource.State.creator,
                        isEqualTo: user.encode())
            .addSnapshotListener { snapshot, error in
                guard let snapshot else {
                    print("Error fetching snapshots: \(error!)")
                    return
                }
                
                snapshot.documentChanges.forEach { diff in
                    let documentId = diff.document.documentID
                    let projectSource = ProjectSourceID(documentId)
                    
                    guard let data = try? diff.document.data(as: ProjectSource.Data.self) else {
                        print("ProjectSource.Doc Decoding Error");
                        return
                    }
                    
                    switch diff.type {
                    case .added:
                        // create ProjectSource
                        let projectSourceRef = ProjectSource(id: projectSource, target: data.target)
                        self.projectSources.insert(projectSourceRef.id)
                        
                        // serve event
                        let event = ProjectHubEvent.added(projectSource, data.target)
                        handler.execute(event)
                    case .modified:
                        // serve event
                        let event = ProjectSourceDiff(target: data.target,
                                                      name: data.name)
                            .getEvent()
                        handler.execute(event)
                    case .removed:
                        // remove ProjectSource
                        ProjectSourceManager.get(projectSource)?.delete()
                        self.projectSources.remove(projectSource)
                        
                        // serve event
                        let event = ProjectHubEvent.removed(data.target)
                        handler.execute(event)
                    }
                }
            }
    }
    package func removeHandler(object: ObjectID) {
        self.listeners[object]?.remove()
        self.listeners[object] = nil
    }
    
    
    // MARK: action
    package func createProjectSource() throws {
        while tickets.isEmpty == false {
            let ticket = tickets.removeFirst()
            
            // create ProjectSource in Firestore
            let data = ProjectSource.Data(name: ticket.name,
                                          creator: ticket.creator,
                                          target: ticket.target,
                                          systemModelCount: 0)
            try db.collection(ProjectSources.name).addDocument(from: data)
        }
    }
    
    
    // MARK: value
    package struct ID: Sendable, Hashable {
        let value: UUID
        
        init(value: UUID = UUID()) {
            self.value = value
        }
    }
}

