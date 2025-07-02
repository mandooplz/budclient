//
//  ProjectBoard.swift
//  BudClient
//
//  Created by 김민우 on 6/25/25.
//
import Foundation
import Tools
import BudServer


// MARK: Object
@MainActor @Observable
public final class ProjectBoard: Debuggable {
    // MARK: core
    init(config: Config<BudClient.ID>) {
        self.id = ID(value: .init())
        self.config = config
        
        ProjectBoardManager.register(self)
    }
    internal func delete() {
        ProjectBoardManager.unregister(self.id)
    }
    
    
    // MARK: state
    internal nonisolated let id: ID
    internal nonisolated let config: Config<BudClient.ID>
    
    internal var updater: ProjectBoardUpdater.ID?
    public var projectForm: ProjectForm.ID?
    
    public internal(set) var projects: [Project.ID] = []
    internal var projectMap: [ProjectSourceID: Project.ID] = [:]
    
    public var issue: (any Issuable)?
    
    
    // MARK: action
    public func setUpUpdater() async {
        await setUpUpdater(mutateHook: nil)
    }
    internal func setUpUpdater(mutateHook: Hook?) async {
        // mutate
        await mutateHook?()
        guard id.isExist else { setIssue(Error.projectBoardIsDeleted); return }
        guard self.updater == nil else { setIssue(Error.alreadySetUp); return }
        
        let myConfig = config.setParent(self.id)
        let updaterRef = ProjectBoardUpdater(config: myConfig)
        self.updater = updaterRef.id
    }
    
    public func subscribeProjectHub() async {
        await self.subscribeProjectHub(addCallback: nil, removeCallback: nil)
    }
    internal func subscribeProjectHub(addCallback: Hook? = nil,
                                      removeCallback: Hook? = nil,
                                      captureHook: Hook? = nil) async {
        // capture
        await captureHook?()
        guard id.isExist else { setIssue(Error.projectBoardIsDeleted); return}
        let config = self.config
        
        // compute
        async let projectHubLink = config.budServerLink.getProjectHub()
        async let ticket = Ticket(system: config.system, user: config.user)
        do {
            try await projectHubLink.setNotifier(
                ticket: ticket,
                notifier: .init(
                    added: { projectSource in
                        Task { @MainActor in
                            guard let updaterRef = self.updater?.ref else { return }
                            
                            updaterRef.diffs.insert(.added(projectSource: projectSource))
                            updaterRef.update()
                            
                            await addCallback?()
                        }
                    },
                    removed: { projectSource in
                        Task { @MainActor in
                            guard let updaterRef = self.updater?.ref else { return }
                            updaterRef.diffs.insert(.removed(projectSource: projectSource))
                            updaterRef.update()
                            await removeCallback?()
                        }
                    }))
        } catch {
            issue = UnknownIssue(error)
            return
        }
    }
    
    public func unsubscribeProjectHub() async {
        await unsubscribeProjectHub(captureHook: nil)
    }
    internal func unsubscribeProjectHub(captureHook: Hook? = nil) async {
        // capture
        await captureHook?()
        guard id.isExist else { setIssue(Error.projectBoardIsDeleted); return}
        let config = config
        let projectHubLink = config.budServerLink.getProjectHub()
        
        // compute
        do {
            try await projectHubLink.removeNotifier(system: config.system)
        } catch {
            issue = UnknownIssue(error)
            return
        }
    }
    
    
    public func createProjectForm() async {
        await self.createProjectForm(mutateHook: nil)
    }
    internal func createProjectForm(mutateHook: Hook?) async {
        // mutate
        await mutateHook?()
        guard id.isExist else { setIssue(Error.projectBoardIsDeleted); return }
        guard projectForm == nil else { setIssue(Error.projectFormAlreadyExist); return }
        
        let myCofig = config.setParent(self.id)
        let projectFormRef = ProjectForm(config: myCofig)
        self.projectForm = projectFormRef.id
    }
    
    
    // MARK: value
    @MainActor
    public struct ID: Sendable, Hashable {
        public let value: UUID
        
        internal var isExist: Bool {
            ProjectBoardManager.container[self] != nil
        }
        public var ref: ProjectBoard? {
            ProjectBoardManager.container[self]
        }
    }
    internal typealias ProjectSourceID = String
    public enum Error: String, Swift.Error {
        case projectBoardIsDeleted
        case updaterIsNotSet, alreadySetUp
        case projectFormAlreadyExist
    }
}


// MARK: Object Manager
@MainActor @Observable
fileprivate final class ProjectBoardManager: Sendable {
    // MARK: state
    fileprivate static var container: [ProjectBoard.ID: ProjectBoard] = [:]
    fileprivate static func register(_ object: ProjectBoard) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: ProjectBoard.ID) {
        container[id] = nil
    }
}

