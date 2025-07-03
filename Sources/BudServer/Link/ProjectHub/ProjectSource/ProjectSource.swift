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


// MARK: Object
@Server
package final class ProjectSource: ServerObject {
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
    
    package var tickets: Deque<ProjectTicket> = []
    package func insert(_ ticket: ProjectTicket) {
        self.tickets.append(ticket)
    }
    
    package func hasHandler(system: SystemID) async throws -> Bool {
        
        fatalError()
    }
    package func setHandler(ticket: Ticket, handler: Handler<ProjectSourceEvent>) {
        // Firebase에 ProjectSource 문서에 대한 리스너 등록
        fatalError()
    }
    package func removeHandler(system: SystemID) async throws {
        fatalError()
    }
    
    // MARK: action
    package func processTicket() async throws {
        guard id.isExist else { return }
        while tickets.isEmpty == false {
            let ticket = tickets.removeFirst()
            let _ = ticket.name
            
            // Firebase로 projects 테이블에 있는 ProjectSource 문서의 name을 수정한다.
        }
    }
    
    package func remove() async throws {
        guard id.isExist else { return }
        // ProjectSource 인스턴스 제거
        ProjectHub.shared.projectSources.remove(self.id)
        self.delete()
        
        // Firebase로 ProjectSource 문서를 삭제한다.
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

