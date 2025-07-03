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
@Server
package final class ProjectSource: ServerObject, Ticketable {
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
    @MainActor private let db = Firestore.firestore()
    
    package var tickets: Deque<ProjectTicket> = []
    
    @MainActor internal var listener: ListenerRegistration?
    @MainActor package func hasHandler(system: SystemID) async throws -> Bool {
        listener != nil
    }
    @MainActor package func setHandler(ticket: Ticket, handler: Handler<ProjectSourceEvent>) {
        // 등록된 listner가 있다면 리턴
        guard listener == nil else { return }
        
        let options = SnapshotListenOptions()
            .withSource(ListenSource.cache)
            .withIncludeMetadataChanges(true)
        
        self.listener = db.collection("projects").document(documentId)
            .addSnapshotListener(options: options) { documentSnapshot, error in
                guard let document = documentSnapshot else {
                    print("Error fetching document: \(error!)")
                    return
                }
                
                let data = document.data() ?? [:]
                let newName = data["name"] as! String
                let event = ProjectSourceEvent.modified(newName)
                
                handler.execute(event)
            }
    }
    @MainActor package func removeHandler(system: SystemID) async throws {
        self.listener?.remove()
        self.listener = nil
    }
    
    
    // MARK: action
    package func processTicket() async throws {
        guard id.isExist else { return }
        while tickets.isEmpty == false {
            let ticket = tickets.removeFirst()
            let newName = ticket.name
            
            // Firebase로 projects 테이블에 있는 ProjectSource 문서의 name을 수정한다.
            Task { @MainActor in
                let document = db.collection("projects").document(documentId)
                
                do {
                    try await document.updateData([
                        "name": newName
                    ])
                } catch {
                    Logger().error("\(self.documentId) 문서를 수정하는 데 실패했습니다.")
                }
            }
        }
    }
    package func remove() async throws {
        guard id.isExist else { return }
        // ProjectSource 인스턴스 제거
        ProjectHub.shared.projectSources.remove(self.id)
        self.delete()
        
        // Firebase로 ProjectSource 문서 삭제
        Task { @MainActor in
            do {
                try await db.collection("projects").document(documentId).delete()
            } catch {
                Logger().error("\(self.documentId) 문서를 삭제하는 데 실패했습니다.")
            }
        }
    }
    
    
    // MARK: value
    @Server
    package struct ID: ServerObjectID {
        package let value: UUID
        package typealias Object = ProjectSource
        package typealias Manager = ProjectSourceManager
    }
    
}


// MARK: Object Manager
@Server
package final class ProjectSourceManager: ServerObjectManager {
    package static var container: [ProjectSource.ID : ProjectSource] = [:]
}

