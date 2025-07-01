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
@BudServer
internal final class ProjectHub: Sendable {
    // MARK: core
    internal static let shared = ProjectHub()
    private init() { }
    
    
    // MARK: state
    internal var tickets: Set<Ticket> = []
    internal nonisolated let id: ID = ID(value: UUID())
    @MainActor private let db = Firestore.firestore()
    @MainActor internal var listener: ListenerRegistration?
    @MainActor internal func isNotifierExist() async -> Bool {
        listener != nil
    }
    
    @MainActor internal func setNotifier(userId: UserID,
                              notifier: ProjectHubLink.Notifier) {
        guard listener == nil else { return }
        self.listener = db.collection("projects")
            .whereField("userId", isEqualTo: userId)
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
    internal func processTicket() async throws {
        for ticket in tickets {
            switch ticket.purpose {
            case .createProjectSource:
                let _ = await MainActor.run {
                    db.collection("projects").addDocument(data: [
                        "name": "UnknownProject",
                        "userId": ticket.userId
                    ])
                }
            }
        }
    }
    
    
    // MARK: value
    internal struct ID: Sendable, Hashable {
        let value: UUID
    }
    internal struct Ticket: Sendable, Hashable {
        let value: UUID
        let userId: String
        let purpose: Purpose
        
        init(userId: String, for purpose: Purpose) {
            self.value = .init()
            self.userId = userId
            self.purpose = purpose
        }
        
        enum Purpose {
            case createProjectSource
        }
    }
}
