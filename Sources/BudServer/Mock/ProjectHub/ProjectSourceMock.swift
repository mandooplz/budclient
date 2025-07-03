//
//  ProjectSourceMock.swift
//  BudClient
//
//  Created by 김민우 on 6/30/25.
//
import Foundation
import Tools


// MARK: Object
@Server
final class ProjectSourceMock: ServerObject {
    // MARK: core
    init(projectHubRef: ProjectHubMock,
         user: String,
         name: String) {
        self.id = ID()
        self.projectHubRef = projectHubRef
        self.user = user
        self.name = name
        
        ProjectSourceMockManager.register(self)
    }
    func delete() {
        ProjectSourceMockManager.unregister(self.id)
    }
    
    
    
    // MARK: state
    nonisolated let id: ID
    nonisolated let projectHubRef: ProjectHubMock
    var user: String // user
    
    var name: String
    var nameTicket: NameTicket?
    
    var notifiers: [SystemID: Notifier] = [:]
    
    
    // MARK: action
    func processNameTicket() async {
        // mutate
        guard let nameTicket else { return }
        let system = nameTicket.ticket.system
        
        for (target, notifier) in notifiers where target != system {
            notifier.whenModifier()
        }
        
        self.nameTicket = nil
    }
    
    
    // MARK: value
    @Server
    struct ID: ServerObjectID {
        let value: UUID
        init(value: UUID = UUID()) {
            self.value = value
        }
        init(_ stringValue: String) {
            self.value = UUID(uuidString: stringValue)!
        }
        typealias Object = ProjectSourceMock
        typealias Manager = ProjectSourceMockManager
    }
    struct NameTicket: Sendable, Hashable {
        let ticket: Ticket
        let name: String
        
        init(ticket: Ticket, name: String) {
            self.ticket = ticket
            self.name = name
        }
    }
    struct Notifier: Sendable {
        let whenModifier: @Sendable () -> Void
        
        init(whenModifier: @Sendable @escaping () -> Void) {
            self.whenModifier = whenModifier
        }
    }
}


// MARK: Object Manager
@Server
final class ProjectSourceMockManager: ServerObjectManager {
    // MARK: state
    static var container: [ProjectSourceMock.ID: ProjectSourceMock] = [:]
}
