//
//  Project.swift
//  BudClient
//
//  Created by 김민우 on 6/25/25.
//
import Foundation
import Tools
import BudServer


// MARK: Object
@MainActor @Observable
public final class Project: Debuggable, EventDebuggable {
    
    // MARK: core
    public init(config: Config<ProjectBoard.ID>,
                sourceLink: ProjectSourceLink) {
        self.id = ID(value: .init())
        self.config = config
        self.sourceLink = sourceLink
        
        ProjectManager.register(self)
    }
    public func delete() {
        ProjectManager.unregister(self.id)
    }
    
    
    // MARK: state
    public nonisolated let id: ID
    public nonisolated let config: Config<ProjectBoard.ID>
    
    nonisolated let sourceLink: ProjectSourceLink
    
    var updater: ProjectUpdater.ID?
    
    public var name: String?
    
    public var issue: (any Issuable)?
    package var callback: Callback?
    
    
    // MARK: action
    public func setUpUpdater() async {
        await setUpUpdater(mutateHook: nil)
    }
    internal func setUpUpdater(mutateHook:Hook?) async {
        // mutate
        await mutateHook?()
        guard id.isExist else { setIssue(Error.projectIsDeleted); return }
        guard updater == nil else { setIssue(Error.updaterAlreadyExist); return}
        let myConfig = self.config.setParent(id)
        
        let updaterRef = ProjectUpdater(config: myConfig)
        self.updater = updaterRef.id
    }
    
    public func subscribeSource() async {
        await subscribeSource(captureHook: nil)
    }
    internal func subscribeSource(captureHook: Hook? = nil) async {
        // capture
        await captureHook?()
        guard id.isExist else { setIssue(Error.projectIsDeleted); return }
        guard let updater else { setIssue(Error.updaterIsNil); return }
        let config = self.config
        let callback = self.callback
        
        // compute
        do {
            let ticket = Ticket(system: config.system, user: config.user)
            try await sourceLink.setHandler(
                ticket: ticket,
                handler: .init({ event in
                    Task { @MainActor in
                        switch event {
                        case .modified:
                            guard let updaterRef = updater.ref else { return }
                            
                            updaterRef.queue.append(event)
                            await updaterRef.update()
                            
                            await callback?()
                        }
                    }
                }))
        } catch {
            setUnknownIssue(error)
            return
        }
        
    }
    
    public func push() async {
        await self.push(captureHook: nil)
    }
    internal func push(captureHook: Hook?) async {
        // capture
        await captureHook?()
        guard id.isExist else { setIssue(Error.projectIsDeleted); return }
        guard let name else { setIssue(Error.nameIsNil); return}
        
        // compute
        do {
            let projectTicket = ProjectTicket(system: config.system,
                                              user: config.user,
                                              name: name)
            
            try await sourceLink.insert(projectTicket)
            try await sourceLink.processTicket()
        } catch {
            setUnknownIssue(error)
            return
        }
    }
    
    public func unsubscribeSource() async {
        await unsubscribeSource(captureHook: nil)
    }
    internal func unsubscribeSource(captureHook: Hook?) async {
        // capture
        await captureHook?()
        guard id.isExist else { setIssue(Error.projectIsDeleted); return }
        let system = config.system
        
        // compute
        do {
            try await sourceLink.removeHandler(system: system)
        } catch {
            setUnknownIssue(error)
            return
        }
    }
    
    public func removeSource() async {
        await self.removeSource(captureHook: nil)
    }
    internal func removeSource(captureHook: Hook?) async {
        // capture
        await captureHook?()
        guard id.isExist else { setIssue(Error.projectIsDeleted); return }
        
        // compute
        do {
            try await sourceLink.remove()
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
            ProjectManager.container[self] != nil
        }
        public var ref: Project? {
            ProjectManager.container[self]
        }
    }
    public enum Error: String, Swift.Error {
        case projectIsDeleted
        case updaterAlreadyExist
        case updaterIsNil
        case nameIsNil
    }
}

// MARK: Object Manager
@MainActor @Observable
fileprivate final class ProjectManager: Sendable {
    // MARK: state
    fileprivate static var container: [Project.ID: Project] = [:]
    fileprivate static func register(_ object: Project) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: Project.ID) {
        container[id] = nil
    }
}
