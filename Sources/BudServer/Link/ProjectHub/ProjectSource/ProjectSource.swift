//
//  ProjectSource.swift
//  BudClient
//
//  Created by 김민우 on 7/3/25.
//
import Foundation
import Tools
import Collections
import FirebaseFirestore
import os


// MARK: Object
@MainActor
package final class ProjectSource: Sendable, Ticketable {
    // MARK: core
    init(documentId: ProjectSourceID) {
        self.documentId = documentId
        
        ProjectSourceManager.register(self)
    }
    func delete() {
        ProjectSourceManager.unregister(self.id)
    }
    
    // MARK: state
    package nonisolated let id: ID = ID(value: UUID())
    package nonisolated let documentId: ProjectSourceID
    private let db = Firestore.firestore()
    
    package var tickets: Deque<ProjectTicket> = []
    
    internal var listener: ListenerRegistration?
    package func hasHandler(system: SystemID) -> Bool {
        listener != nil
    }
    package func setHandler(ticket: Ticket, handler: Handler<ProjectSourceEvent>) {
        guard listener == nil else { return }
        self.listener = db.collection("projects").document(documentId)
            .addSnapshotListener { documentSnapshot, error in
                guard let document = documentSnapshot else {
                    Logger().error("Error fetching document: \(error!)")
                    return
                }
                
                let data = document.data() ?? [:]
                guard let newName = data["name"] as? String else {
                    Logger().error("Invalid or missing 'name' field in document: \(document.documentID)")
                    return
                }
                let event = ProjectSourceEvent.modified(newName)
                
                handler.execute(event)
            }
    }
    package func removeHandler(system: SystemID) {
        self.listener?.remove()
        self.listener = nil
    }
    
    
    // MARK: action
    package func processTicket() {
        guard id.isExist else { return }
        while tickets.isEmpty == false {
            let ticket = tickets.removeFirst()
            let newName = ticket.name
            
            // Firebase로 projects 테이블에 있는 ProjectSource 문서의 name을 수정한다.
            let document = db.collection("projects").document(documentId)
            document.updateData([
                "name": newName
            ])
        }
    }
    package func remove() {
        guard id.isExist else { return }
        // ProjectSource 인스턴스 제거
        ProjectHub.shared.projectSources.remove(self.id)
        self.delete()
        
        // Firebase로 ProjectSource 문서 삭제
        db.collection("projects").document(documentId).delete()
    }
    
    
    // MARK: value
    @MainActor
    package struct ID: Sendable, Hashable {
        package let value: UUID
        var isExist: Bool {
            ProjectSourceManager.container[self] != nil
        }
        var ref: ProjectSource? {
            ProjectSourceManager.container[self]
        }
    }
    
}


// MARK: Object Manager
@MainActor
fileprivate final class ProjectSourceManager: Sendable {
    fileprivate static var container: [ProjectSource.ID : ProjectSource] = [:]
    fileprivate static func register(_ object: ProjectSource) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: ProjectSource.ID) {
        container[id] = nil
    }
}

