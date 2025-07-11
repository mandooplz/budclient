//
//  ProjectBoard.swift
//  BudClient
//
//  Created by 김민우 on 6/25/25.
//
import Foundation
import Values
import BudServer

private let logger = WorkFlow.getLogger(for: "ProjectBoard")


// MARK: Object
@MainActor @Observable
public final class ProjectBoard: Debuggable, EventDebuggable {
    // MARK: core
    init(config: Config<BudClient.ID>) {
        self.config = config
        self.updater = ProjectBoardUpdater(config: config.setParent(self.id))
        
        ProjectBoardManager.register(self)
    }
    func delete() {
        ProjectBoardManager.unregister(self.id)
    }
    
    
    // MARK: state
    public nonisolated let id = ID()
    public nonisolated let config: Config<BudClient.ID>
    
    var updater: ProjectBoardUpdater
    
    public internal(set) var editors: [ProjectEditor.ID] = []
    func getProjectEditor(_ target: ProjectID) -> ProjectEditor.ID? {
        self.editors.first { $0.ref?.target == target }
    }
    func isEditorExist(target: ProjectID) -> Bool {
        self.editors.lazy
            .compactMap { $0.ref }
            .contains { $0.target == target }
    }
    
    public var issue: (any Issuable)?
    package var callback: Callback?
    
    
    // MARK: action
    public func subscribe() async {
        await self.subscribe(captureHook: nil)
    }
    func subscribe(captureHook: Hook?) async {
        // capture
        await captureHook?()
        guard self.id.isExist else { setIssue(Error.projectBoardIsDeleted); return }
        let config = self.config
        let callback = self.callback
        let me = ObjectID(id.value)
        let projectBoard = self.id
        
        // compute
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let budServerRef = await config.budServer.ref,
                      let projectHubRef = await budServerRef.projectHub.ref else { return }
                
                let isSubscribed = await projectHubRef.hasHandler(requester: me)
                guard isSubscribed == false else {
                    await projectBoard.ref?.setIssue(Error.alreadySubscribed);
                    return
                }
                
                await projectHubRef.setHandler(
                    requester: me,
                    user: config.user,
                    handler: .init({ event, workflow in
                        Task {
                            await WorkFlow.with(workflow) {
                                guard let updaterRef = await projectBoard.ref?.updater else {
                                    logger.failure("ProjectBoard가 존재하지 않음")
                                    return
                                }
                                
                                await updaterRef.appendEvent(event)
                                await updaterRef.update()
                                
                                await callback?()
                            }
                        }
                    })
                )
            }
        }
        
        logger.success()
    }
    
    public func unsubscribe() async {
        // capture
        let config = self.config
        let me = ObjectID(id.value)
        
        // compute
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let budServerRef = await config.budServer.ref,
                      let projectHubRef = await budServerRef.projectHub.ref else {
                    return }
                
                await projectHubRef.removeHandler(requester: me)
            }
        }
        
        logger.success()
    }
    
    public func createNewProject() async {
        await self.createProject(captureHook: nil)
    }
    func createProject(captureHook: Hook?) async {
        // capture
        await captureHook?()
        guard id.isExist else { setIssue(Error.projectBoardIsDeleted); return }
        let config = self.config
        
        
        // compute
        do {
            try await withThrowingDiscardingTaskGroup { group in
                group.addTask {
                    let newProject = ProjectID()
                    let newName = "Project \(Int.random(in: 1..<1000))"
                    
                    async let ticket = CreateProject(
                        creator: config.user,
                        target: newProject,
                        name: newName)
                    
                    guard let budServerRef = await config.budServer.ref,
                          let projectHubRef = await budServerRef.projectHub.ref else { return }
                    
                    
                    await projectHubRef.insertTicket(ticket)
                    try await projectHubRef.createNewProject()
                }
            }
        } catch {
            logger.failure(error)
            setUnknownIssue(error)
            return
        }
        logger.success()
    }
    
    
    // MARK: value
    @MainActor
    public struct ID: Sendable, Hashable {
        let value: UUID
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
        case alreadySubscribed
        case alreadySetUp
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

