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
public final class ProjectBoard: Debuggable, EventDebuggable {
    // MARK: core
    init(config: Config<BudClient.ID>) {
        self.config = config
        
        ProjectBoardManager.register(self)
    }
    func delete() {
        ProjectBoardManager.unregister(self.id)
    }
    
    
    // MARK: state
    public nonisolated let id = ID()
    public nonisolated let config: Config<BudClient.ID>
    
    var updater: ProjectBoardUpdater.ID?
    
    public internal(set) var projects: [Project.ID] = []
    var projectSourceMap: [ProjectSourceID: Project.ID] = [:]
    func getProjectSource(_ project: Project.ID) -> ProjectSourceID? {
        self.projectSourceMap
            .first { $0.value == project }?
            .key
    }
    
    public var issue: (any Issuable)?
    package var callback: Callback?
    
    
    // MARK: action
    public func setUpUpdater() async {
        await setUpUpdater(mutateHook: nil)
    }
    func setUpUpdater(mutateHook: Hook?) async {
        // mutate
        await mutateHook?()
        guard id.isExist else { setIssue(Error.projectBoardIsDeleted); return }
        guard self.updater == nil else { setIssue(Error.alreadySetUp); return }
        let config = self.config
        
        let myConfig = config.setParent(self.id)
        let updaterRef = ProjectBoardUpdater(config: myConfig)
        self.updater = updaterRef.id
    }
    
    public func subscribeProjectHub() async {
        await self.subscribeProjectHub(captureHook: nil)
    }
    func subscribeProjectHub(captureHook: Hook?) async {
        // capture & compute
        await captureHook?()
        guard self.id.isExist else { setIssue(Error.projectBoardIsDeleted); return }
        guard let updater else { setIssue(Error.updaterIsNotSet); return }
        let config = self.config
        let callback = self.callback
        
        
        let projectHubLink = await config.budServerLink.getProjectHub()
        let ticket = Ticket(system: config.system, user: config.user)
        await withDiscardingTaskGroup { group in
            group.addTask {
                await projectHubLink.setHandler(
                    ticket: ticket,
                    handler: .init({ event in
                        Task { @MainActor in
                            switch event {
                            case .added:
                                guard let updaterRef = updater.ref else { return }
                                
                                updaterRef.queue.append(event)
                                await updaterRef.update()
                                
                                await callback?()
                            case .removed:
                                guard let updaterRef = updater.ref else { return }
                                
                                updaterRef.queue.append(event)
                                await updaterRef.update()
                                
                                await callback?()
                            }
                        }
                    })
                )
            }
        }
    }
    
    public func unsubscribeProjectHub() async {
        await unsubscribeProjectHub(captureHook: nil)
    }
    func unsubscribeProjectHub(captureHook: Hook? = nil) async {
        // capture & compute
        await captureHook?()
        guard id.isExist else { setIssue(Error.projectBoardIsDeleted); return}
        let config = config
        
        await withDiscardingTaskGroup { group in
            group.addTask {
                let projectHubLink = await config.budServerLink.getProjectHub()
                await projectHubLink.removeHandler(system: config.system)
            }
        }
    }
    
    
    public func createProjectSource() async {
        await self.createProjectSource(captureHook: nil)
    }
    func createProjectSource(captureHook: Hook?) async {
        // capture & compute
        await captureHook?()
        guard id.isExist else { setIssue(Error.projectBoardIsDeleted); return}
        guard updater != nil else { setIssue(Error.updaterIsNotSet); return }
        let config = self.config
        let budServerLink = config.budServerLink
        let newProjectName = "Project\(self.projects.count + 1)"
        
        await withDiscardingTaskGroup { group in
            group.addTask {
                let projectHubLink = await budServerLink.getProjectHub()
                let projectTicket = ProjectTicket(
                    system: config.system,
                    user: config.user,
                    name: newProjectName)
                await projectHubLink.insertTicket(projectTicket)
                await projectHubLink.createProjectSource()
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
            ProjectBoardManager.container[self] != nil
        }
        public var ref: ProjectBoard? {
            ProjectBoardManager.container[self]
        }
    }
    public enum Error: String, Swift.Error {
        case projectBoardIsDeleted
        case updaterIsNotSet, alreadySetUp
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

