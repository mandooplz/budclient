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
    init(idValue: String) {
        self.id = ID(value: idValue)
        
        ProjectSourceManager.register(self)
    }
    func delete() {
        ProjectSourceManager.unregister(self.id)
    }
    
    // MARK: state
    nonisolated let id: ID
    nonisolated let target: ProjectID
    
    private let db = Firestore.firestore()
    
    package var tickets: Deque<ProjectTicket> = []
    
    var listener: ListenerRegistration?
    package func hasHandler(system: SystemID) -> Bool {
        listener != nil
    }
    package func setHandler(ticket: Ticket, handler: Handler<ProjectSourceEvent>) {
        guard listener == nil else { return }
        self.listener = db.collection(DB.ProjectSources).document(id.value)
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
    package func processTicket() throws {
        guard id.isExist else { return }
        while tickets.isEmpty == false {
            let ticket = tickets.removeFirst()
            let newName = ticket.name
            
            // FireStore의 Projects 테이블에 있는 ProjectSource 문서의 name을 수정한다.
            let updateData = Data(name: newName, target: target)
            
            let document = db.collection(DB.ProjectSources).document(id.value)
            try document.setData(from: updateData)
        }
    }
    package func remove() {
        guard id.isExist else { return }
        
        // ProjectSource 인스턴스 제거
        ProjectHub.shared.projectSources.remove(self.id)
        self.delete()
        
        // FireStore에서 문서 삭제
        db.collection(DB.ProjectSources).document(id.value).delete()
    }
    
    
    // MARK: value
    @MainActor
    package struct ID: Sendable, Hashable {
        let value: String
        
        var isExist: Bool {
            ProjectSourceManager.container[self] != nil
        }
        package var ref: ProjectSource? {
            ProjectSourceManager.container[self]
        }
    }
    package struct Data: Hashable, Codable {
        @DocumentID var id: String?
        package var name: String
        package var target: ProjectID
        
        init(id: String? = nil, name: String, target: ProjectID) {
            self.id = id
            self.name = name
            self.target = target
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

