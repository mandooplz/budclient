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
    private let db = Firestore.firestore()
    
    
    // MARK: action
    internal func processTicket() async throws {
        for ticket in tickets {
            switch ticket.purpose {
            case .createProjectSource:
                do {
                    try await db.collection("projects").addDocument(data: [
                        "name": "UnknownProject",
                        "userId": ticket.userId
                    ])
                    tickets.remove(ticket)
                } catch {
                    throw error
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
