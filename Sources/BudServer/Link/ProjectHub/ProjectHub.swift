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
    
    var projectSources: Set<ProjectSource.ID> = []
    func getProjectSource(_ documentId: String) -> ProjectSource.ID? {
        self.projectSources.lazy
            .compactMap { $0.ref }
            .first { $0.documentId == documentId }?
            .id
    }
    
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
                        let projectSource = diff.document.documentID
                        
                        let projectSourceRef = ProjectSource(documentId: projectSource)
                        self.projectSources.insert(projectSourceRef.id)
                        
                        let event = ProjectHubEvent.added(projectSource)
                        handler.execute(event)
                    }
                    if (diff.type == .removed) {
                        let projectSource = diff.document.documentID
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
            let documentID = db.collection("projects").addDocument(data: [
                "name": ticket.name,
                "user": ticket.user
            ]).documentID
            
            let projectSourceRef = ProjectSource(documentId: documentID)
            projectSources.insert(projectSourceRef.id)
        }
    }
    
    // MARK: value
    internal struct ID: Sendable, Hashable {
        let value: UUID
    }
}
