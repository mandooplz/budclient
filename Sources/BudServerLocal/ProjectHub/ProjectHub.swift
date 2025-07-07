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
    package var projectSourceMap: [ProjectID: ProjectSourceID] = [:]
    
    package var tickets: Deque<CreateProjectSource> = []
    
    package var listener: ListenerRegistration?
    package func hasHandler() async -> Bool {
        listener != nil
    }
    package func setHandler(ticket: SubscribeProjectHub,
                            handler: Handler<ProjectHubEvent>) {
        guard listener == nil else { return }
        
        self.listener = db.collection(ProjectSources.name)
            .whereField(ProjectSource.State.creator,
                        isEqualTo: ticket.user.encode())
            .addSnapshotListener { snapshot, error in
                guard let snapshot else {
                    print("Error fetching snapshots: \(error!)")
                    return
                }
                
                snapshot.documentChanges.forEach { diff in
                    let documentId = diff.document.documentID
                    let object = ProjectSourceID(documentId)
                    
                    guard let data = try? diff.document.data(as: ProjectSource.Data.self) else {
                        Logger().error("ProjectSource.Doc Decoding Error"); return
                    }
                    
                    if (diff.type == .added) {
                        let projectSourceRef = ProjectSource(id: object, target: data.target)
                        self.projectSources.insert(projectSourceRef.id)
                        
                        let event = ProjectHubEvent.added(object, data.target)
                        handler.execute(event)
                    }
                    
                    if (diff.type == .removed) {
                        let event = ProjectHubEvent.removed(data.target)
                        handler.execute(event)
                    }
                }
            }
    }
    package func removeHandler() {
        self.listener?.remove()
        self.listener = nil
    }
    
    
    // MARK: action
    package func createProjectSource() throws {
        while tickets.isEmpty == false {
            let ticket = tickets.removeFirst()
            
            // 새로운 FireStore Document 생성
            let data = ProjectSource.Data(name: ticket.name,
                                          creator: ticket.creator,
                                          target: ticket.target)
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

