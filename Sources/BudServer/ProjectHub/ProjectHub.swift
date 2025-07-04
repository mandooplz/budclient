//
//  ProjectHub.swift
//  BudClient
//
//  Created by 김민우 on 6/30/25.
//
import Foundation
import Tools
import Collections
import FirebaseFirestore


// MARK: Object
@MainActor
internal final class ProjectHub: Sendable, Ticketable {
    // MARK: core
    static let shared = ProjectHub()
    private init() { }
    
    
    // MARK: state
    nonisolated let id: ID = ID(value: UUID())
    private let db = Firestore.firestore()
    
    var projectSources: Set<ProjectSourceID> = []
    
    internal var tickets: Deque<ProjectTicket> = []
    
    internal var listener: ListenerRegistration?
    internal func hasHandler() async -> Bool {
        listener != nil
    }
    internal func setHandler(ticket: Ticket,
                                        handler: Handler<ProjectHubEvent>) {
        guard listener == nil else { return }
        self.listener = db.collection("projects")
            .whereField("user", isEqualTo: ticket.user)
            .addSnapshotListener { querySnapshot, error in
                guard let snapshot = querySnapshot else {
                    print("Error fetching snapshots: \(error!)")
                    return
                }
                
                snapshot.documentChanges.forEach { diff in
                    if (diff.type == .added) {
                        let documentId = diff.document.documentID
                        let projectSource = ProjectSourceID(documentId)
                        
                        let projectSourceRef = ProjectSource(id: projectSource)
                        self.projectSources.insert(projectSourceRef.id)
                        
                        let event = ProjectHubEvent.added(projectSource)
                        handler.execute(event)
                    }
                    if (diff.type == .removed) {
                        let documentId = diff.document.documentID
                        let projectSource = ProjectSourceID(documentId)
                        
                        let event = ProjectHubEvent.removed(projectSource)
                        handler.execute(event)
                    }
                }
            }
    }
    internal func removeHandler() {
        self.listener?.remove()
        self.listener = nil
    }
    
    
    // MARK: action
    internal func createProjectSource() {
        while tickets.isEmpty == false {
            let ticket = tickets.removeFirst()
            
            // 새로운 FireStore Document 생성
            db.collection("projects").addDocument(data: [
                "name": ticket.name,
                "user": ticket.user
            ])
        }
    }
    
    // MARK: value
    internal struct ID: Sendable, Hashable {
        let value: UUID
    }
}
