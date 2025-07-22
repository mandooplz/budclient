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
public final class ProjectBoard: Debuggable, EventDebuggable, Hookable {
    // MARK: core
    init(config: Config<BudClient.ID>) {
        self.config = config
        self.updaterRef = Updater(owner: self.id)
        
        ProjectBoardManager.register(self)
    }
    func delete() {
        ProjectBoardManager.unregister(self.id)
    }
    
    
    // MARK: state
    nonisolated let id = ID()
    nonisolated let config: Config<BudClient.ID>
    nonisolated let updaterRef: Updater
    
    var isUpdating: Bool = false
    
    public internal(set) var projects = OrderedDictionary<ProjectID, ProjectModel.ID>()
    
    public var issue: (any IssueRepresentable)?
    package var callback: Callback?
    
    package var captureHook: Hook? = nil
    package var computeHook: Hook? = nil
    package var mutateHook: Hook? = nil
    
    
    // MARK: action
    public func startUpdating() async {
        logger.start()
        
        // capture
        await captureHook?()
        guard self.id.isExist else {
            setIssue(Error.projectBoardIsDeleted)
            logger.failure("ProjectBoard가 존재하지 않아 실행 취소됩니다.")
            return
        }
        guard isUpdating == false else {
            setIssue(Error.alreadyUpdating)
            logger.failure("이미 updating 중입니다.")
            return
        }
        let config = self.config
        let me = ObjectID(self.id.value)
        
        // compute
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let budServerRef = await config.budServer.ref,
                      let projectHubRef = await budServerRef.getProjectHub(config.user).ref else {
                    logger.failure("User의 ProjectHub가 존재하지 않습니다.")
                    return
                }
                
                await projectHubRef.appendHandler(
                    requester: me,
                    .init({ event in
                        Task { [weak self] in
                            await self?.updaterRef.appendEvent(event)
                            await self?.updaterRef.update()
                            
                            await self?.callback?()
                        }
                    })
                )
                
                await projectHubRef.registerSync(me)
                await projectHubRef.synchronize()
            }
        }
        
        // mutate
        self.isUpdating = true
    }
    
    public func createProject() async {
        logger.start()
        
        // capture
        await captureHook?()
        guard id.isExist else {
            setIssue(Error.projectBoardIsDeleted)
            logger.failure("ProjectBoard가 존재하지 않아 실행 취소됩니다.")
            return
        }
        let config = self.config
        
        
        // compute
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let budServerRef = await config.budServer.ref,
                      let projectHubRef = await budServerRef.getProjectHub(config.user).ref else {
                    logger.failure("ProjectHub가 존재하지 않습니다.")
                    return
                }
                
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
        case alreadyUpdating
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
