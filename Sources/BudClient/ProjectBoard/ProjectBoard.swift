//
//  ProjectBoard.swift
//  BudClient
//
//  Created by 김민우 on 6/25/25.
//
import Foundation
import Values
import Collections
import BudServer

private let logger = BudLogger("ProjectBoard")


// MARK: Object
@MainActor @Observable
public final class ProjectBoard: Debuggable, EventDebuggable {
    // MARK: core
    init(config: Config<BudClient.ID>) {
        self.config = config
        self.updater = Updater(owner: self.id)
        
        ProjectBoardManager.register(self)
    }
    func delete() {
        ProjectBoardManager.unregister(self.id)
    }
    
    
    // MARK: state
    nonisolated let id = ID()
    nonisolated let config: Config<BudClient.ID>
    nonisolated let updater: Updater
    
    public internal(set) var projects = OrderedDictionary<ProjectID, ProjectModel.ID>()
    
    public var issue: (any IssueRepresentable)?
    public var callback: Callback?
    
    
    // MARK: action
    public func startUpdating() async {
        logger.start()
        
        await self.startUpdating(captureHook: nil)
    }
    func startUpdating(captureHook: Hook?) async {
        // capture
        await captureHook?()
        guard self.id.isExist else {
            setIssue(Error.projectBoardIsDeleted)
            logger.failure("ProjectBoard가 존재하지 않아 실행 취소됩니다.")
            return
        }
        let projectBoard = self.id
        let config = self.config
        
        // compute
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let budServerRef = await config.budServer.ref,
                      let projectHubRef = await budServerRef.getProjectHub(config.user).ref else {
                    let log = logger.getLog("ProjectHub가 존재하지 않습니다.")
                    logger.raw.fault("\(log)")
                    return
                }
                
                await projectHubRef.setHandler(
                    .init({ event in
                        Task {
                            await WorkFlow {
                                guard let projectBoardRef = await projectBoard.ref else {
                                    return
                                }
                                
                                let updaterRef = projectBoardRef.updater
                                
                                await updaterRef.appendEvent(event)
                                await updaterRef.update()
                                
                                await projectBoardRef.callback?()
                                await projectBoardRef.setCallbackNil()
                            }
                        }
                    })
                )
            }
        }
    }
    
    public func createProject() async {
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
                guard let budServerRef = await config.budServer.ref,
                      let projectHubRef = await budServerRef.getProjectHub(config.user).ref else { return }
                
                await projectHubRef.createProject()
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
