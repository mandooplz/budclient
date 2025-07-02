//
//  ProjectForm.swift
//  BudClient
//
//  Created by 김민우 on 7/1/25.
//
import Foundation
import Tools


// MARK: Object
@MainActor @Observable
public final class ProjectForm: Debuggable {
    // MARK: core
    init(config: Config<ProjectBoard.ID>) {
        self.id = ID(value: UUID())
        self.config = config
        
        ProjectFormManager.register(self)
    }
    func delete() {
        ProjectFormManager.unregister(self.id)
    }
    
    
    // MARK: state
    internal nonisolated let id: ID
    internal nonisolated let config: Config<ProjectBoard.ID>
    
    public var name: String?
    
    public var issue: (any Issuable)?
    
    
    // MARK: action
    public func submit() async {
        await self.submit(computeHook: nil)
    }
    internal func submit(computeHook: Hook? = nil) async {
        // capture
        
        // compute
        await computeHook?()
        guard id.isExist else { setIssue(Error.projectFormIsDeleted); return }
        let budServerLink = config.budServerLink
        let projectHubLink = budServerLink.getProjectHub()
        
        do {
            let ticket = Ticket(system: config.system, user: config.user)
            await projectHubLink.insertTicket(ticket)
            try await projectHubLink.createProjectSource()
        } catch {
            setUnknownIssue(error)
            return
        }
    }
    
    
    // MARK: value
    @MainActor
    public struct ID: Sendable, Hashable {
        public let value: UUID
        
        internal var isExist: Bool {
            ProjectFormManager.container[self] != nil
        }
        public var ref: ProjectForm? {
            ProjectFormManager.container[self]
        }
    }
    public enum Error: String, Swift.Error {
        case projectFormIsDeleted
        case projectNameIsNil
    }
}


// MARK: ObjectManager
@MainActor @Observable
fileprivate final class ProjectFormManager: Sendable {
    // MARK: state
    fileprivate static var container: [ProjectForm.ID: ProjectForm] = [:]
    fileprivate static func register(_ object: ProjectForm) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: ProjectForm.ID) {
        container[id] = nil
    }
}
