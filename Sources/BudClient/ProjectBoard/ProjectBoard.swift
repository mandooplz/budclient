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
    public var callback: Callback?
    
    
    // MARK: action
    public func subscribe() async {
        logger.start()
        
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
                      let projectHubRef = await budServerRef.projectHub.ref else {
                    let log = logger.getLog("ProjectHub가 존재하지 않습니다.")
                    logger.raw.fault("\(log)")
                    return
                }
                
                let isSubscribed = await projectHubRef.hasHandler(requester: me)
                guard isSubscribed == false else {
                    await projectBoard.ref?.setIssue(Error.alreadySubscribed)
                    let log = logger.getLog(Error.alreadySubscribed)
                    logger.raw.error("\(log)")
                    return
                }
                
                await projectHubRef.setHandler(
                    requester: me,
                    user: config.user,
                    handler: .init({ event in
                        Task {
                            await WorkFlow {
                                guard let updaterRef = await projectBoard.ref?.updater else {
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
    }
    
    public func unsubscribe() async {
        logger.start()
        
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
    }
    
    public func createNewProject() async {
        logger.start()
        
        await self.createProject(captureHook: nil)
    }
    func createProject(captureHook: Hook?) async {
        // capture
        await captureHook?()
        guard id.isExist else { setIssue(Error.projectBoardIsDeleted); return }
        let config = self.config
        
        
        // compute
        await withDiscardingTaskGroup { group in
            group.addTask {
                async let ticket = CreateProject(by: config.user)
                
                guard let budServerRef = await config.budServer.ref,
                      let projectHubRef = await budServerRef.projectHub.ref else { return }
                
                
                await projectHubRef.insertTicket(ticket)
                await projectHubRef.createNewProject()
            }
        }
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

