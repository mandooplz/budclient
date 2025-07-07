//
//  Project.swift
//  BudClient
//
//  Created by 김민우 on 6/25/25.
//
import Foundation
import Values
import BudServer


// MARK: Object
@MainActor @Observable
public final class Project: Debuggable, EventDebuggable {
    
    // MARK: core
    init(config: Config<ProjectBoard.ID>,
         target: ProjectID,
         sourceLink: ProjectSourceLink) {
        self.config = config
        self.target = target
        self.sourceLink = sourceLink
        
        ProjectManager.register(self)
    }
    func delete() {
        ProjectManager.unregister(self.id)
    }
    
    
    // MARK: state
    public nonisolated let id = ID()
    public nonisolated let config: Config<ProjectBoard.ID>
    nonisolated let target: ProjectID
    nonisolated let sourceLink: ProjectSourceLink
    
    public var name: String?
    public var systemBoard: SystemBoard.ID?
    public var flowBoard: FlowBoard.ID?
    
    var updater: ProjectUpdater.ID?
    
    public var issue: (any Issuable)?
    package var callback: Callback?
    
    
    // MARK: action
    public func setUp() async {
        await setUp(mutateHook: nil)
    }
    func setUp(mutateHook:Hook?) async {
        // mutate
        await mutateHook?()
        guard id.isExist else { setIssue(Error.projectIsDeleted); return }
        guard updater == nil, systemBoard == nil, flowBoard == nil else { setIssue(Error.alreadySetUp); return }
        let myConfig = self.config.setParent(id)
        
        let updaterRef = ProjectUpdater(config: myConfig)
        let systemBoardRef = SystemBoard()
        let flowBoardRef = FlowBoard()
        
        self.updater = updaterRef.id
        self.systemBoard = systemBoardRef.id
        self.flowBoard = flowBoardRef.id
    }
    
    public func subscribeSource() async {
        await subscribeSource(captureHook: nil)
    }
    internal func subscribeSource(captureHook: Hook? = nil) async {
        // capture
        await captureHook?()
        guard id.isExist else { setIssue(Error.projectIsDeleted); return }
        guard let updater else { setIssue(Error.updaterIsNil); return }
        let callback = self.callback
        let sourceLink = self.sourceLink
        let (me, target) = (ObjectID(self.id.value), self.target)
        
        // compute
        await withDiscardingTaskGroup { group in
            group.addTask {
                let ticket = SubscrieProjectSource(object: me, target: target)
                await sourceLink.setHandler(
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
                    }
                                  )
                )
            }
        }
    }
    
    public func push() async {
        await self.push(captureHook: nil)
    }
    func push(captureHook: Hook?) async {
        // capture
        await captureHook?()
        guard id.isExist else { setIssue(Error.projectIsDeleted); return }
        guard let name else { setIssue(Error.nameIsNil); return}
        let sourceLink = self.sourceLink
        
        // compute
        do {
            try await withThrowingDiscardingTaskGroup { group in
                group.addTask {
                    let editTicket = EditProjectSourceName(name)
                    
                    try await sourceLink.insert(editTicket)
                    try await sourceLink.processTicket()
                }
            }
        } catch {
            setUnknownIssue(error); return
        }
    }
    
    public func unsubscribeSource() async {
        await unsubscribeSource(captureHook: nil)
    }
    func unsubscribeSource(captureHook: Hook?) async {
        // capture
        await captureHook?()
        guard id.isExist else { setIssue(Error.projectIsDeleted); return }
        let sourceLink = self.sourceLink
        let me = ObjectID(id.value)
        
        // compute
        await withDiscardingTaskGroup { group in
            group.addTask {
                await sourceLink.removeHandler(object: me)
            }
        }
    }
    
    public func removeSource() async {
        await self.removeSource(captureHook: nil)
    }
    func removeSource(captureHook: Hook?) async {
        // capture
        await captureHook?()
        guard id.isExist else { setIssue(Error.projectIsDeleted); return }
        let sourceLink = self.sourceLink
        
        // compute
        await withDiscardingTaskGroup { group in
            group.addTask {
                await sourceLink.remove()
            }
        }
    }
    
    
    // MARK: value
    @MainActor
    public struct ID: Sendable, Hashable {
        public let value: UUID
        nonisolated init(value: UUID = UUID()) {
            self.value = value
        }
        
        var isExist: Bool {
            ProjectManager.container[self] != nil
        }
        public var ref: Project? {
            ProjectManager.container[self]
        }
    }
    public enum Error: String, Swift.Error {
        case projectIsDeleted
        case alreadySetUp
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
