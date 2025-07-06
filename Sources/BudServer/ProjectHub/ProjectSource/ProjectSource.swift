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
    init(id: ProjectSourceID = ProjectSourceID()) {
        self.id = id
        
        ProjectSourceManager.register(self)
    }
    func delete() {
        ProjectSourceManager.unregister(self.id)
    }
    
    // MARK: state
    package nonisolated let id: ProjectSourceID
    private typealias Manager = ProjectSourceManager
    private let db = Firestore.firestore()
    
    package var tickets: Deque<ProjectTicket> = []
    
    var listener: ListenerRegistration?
    package func hasHandler(system: SystemID) -> Bool {
        listener != nil
    }
    package func setHandler(ticket: Ticket, handler: Handler<ProjectSourceEvent>) {
        guard listener == nil else { return }
        self.listener = db.collection(DB.ProjectSources).document(id.toString)
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
        guard Manager.isExist(id) else { return }
        while tickets.isEmpty == false {
            let ticket = tickets.removeFirst()
            let newName = ticket.name
            
            // Firebase로 projects 테이블에 있는 ProjectSource 문서의 name을 수정한다.
            let document = db.collection(DB.ProjectSources).document(id.toString)
            document.updateData([
                "name": newName
            ])
        }
    }
    package func remove() {
        guard Manager.isExist(id) else { return }
        // ProjectSource 인스턴스 제거
        ProjectHub.shared.projectSources.remove(self.id)
        self.delete()
        
        // Firebase로 ProjectSource 문서 삭제
        db.collection(DB.ProjectSources).document(id.toString).delete()
    }
}


// MARK: Object Manager
@MainActor
package final class ProjectSourceManager: Sendable {
    fileprivate static var container: [ProjectSourceID : ProjectSource] = [:]
    fileprivate static func register(_ object: ProjectSource) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: ProjectSourceID) {
        container[id] = nil
    }
    package static func get(_ id: ProjectSourceID) -> ProjectSource? {
        container[id]
    }
    package static func isExist(_ id: ProjectSourceID) -> Bool {
        container[id] != nil
    }
}

