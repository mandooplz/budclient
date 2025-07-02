//
//  ProjectHub.swift
//  BudClient
//
//  Created by 김민우 on 6/30/25.
//
import Foundation
import Tools
import FirebaseFirestore


// MARK: Object
@Server
internal final class ProjectHub: Sendable {
    // MARK: core
    internal static let shared = ProjectHub()
    private init() { }
    
    
    // MARK: state
    internal nonisolated let id: ID = ID(value: UUID())
    @MainActor private let db = Firestore.firestore()
    
    internal var tickets: Set<Ticket> = []
    
    @MainActor internal var listener: ListenerRegistration?
    @MainActor internal func hasNotifier() async -> Bool {
        listener != nil
    }
    
    @MainActor internal func setNotifier(ticket: Ticket, notifier: ProjectHubLink.Notifier) {
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
                        notifier.added(projectSource)
                    }
                    if (diff.type == .removed) {
                        let projectSource = diff.document.documentID
                        notifier.removed(projectSource)
                    }
                }
            }
    }
    @MainActor internal func removeNotifier() {
        self.listener?.remove()
        self.listener = nil
    }
    
    
    // MARK: action
    internal func createProjectSource() async throws {
        for ticket in tickets {
            let _ = await MainActor.run {
                db.collection("projects").addDocument(data: [
                    "name": "UnknownProject",
                    "user": ticket.user
                ])
            }
        }
    }
    
    
    // MARK: value
    internal struct ID: Sendable, Hashable {
        let value: UUID
    }
}
