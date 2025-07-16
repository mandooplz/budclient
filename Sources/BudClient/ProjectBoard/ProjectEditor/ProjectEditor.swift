//
//  ProjectEditor.swift
//  BudClient
//
//  Created by 김민우 on 6/25/25.
//
import Foundation
import Values
import BudServer

private let logger = WorkFlow.getLogger(for: "ProjectEditor")


// MARK: Object
@MainActor @Observable
public final class ProjectEditor: Debuggable {
    // MARK: core
    init(config: Config<ProjectBoard.ID>,
         target: ProjectID,
         name: String,
         source: any ProjectSourceIdentity) {
        self.config = config
        self.target = target
        self.name = name
        self.nameInput = name
        self.source = source
        
        ProjectManager.register(self)
    }
    func delete() {
        ProjectManager.unregister(self.id)
    }
    
    
    // MARK: state
    nonisolated let id = ID()
    nonisolated let config: Config<ProjectBoard.ID>
    nonisolated let target: ProjectID
    nonisolated let source: any ProjectSourceIdentity
    
    public internal(set) var name: String
    public var nameInput: String
    public func setNameInput(_ value: String) {
        self.nameInput = value
    }
    
    
    public var systemBoard: SystemBoard.ID?
    public var flowBoard: FlowBoard.ID?
    public var componentBoard: ComponentBoard.ID?
    
    public var issue: (any Issuable)?
    
    
    // MARK: action
    public func setUp() async {
        logger.start()
        
        await setUp(mutateHook: nil)
    }
    func setUp(mutateHook:Hook?) async {
        // mutate
        await mutateHook?()
        guard id.isExist else {
            setIssue(Error.editorIsDeleted)
            logger.failure("ProjectEditor가 존재하지 않아 실행 취소됩니다.")
            return
        }
        guard systemBoard == nil &&
                flowBoard == nil &&
                componentBoard == nil else { setIssue(Error.alreadySetUp)
            logger.failure("이미 setUp된 상태입니다.")
            return
        }
        let myConfig = self.config.setParent(id)
        
        let systemBoardRef = SystemBoard(config: myConfig)
        let flowBoardRef = FlowBoard(config: myConfig)
        let componentBoardRef = ComponentBoard(config: myConfig)
        
        self.systemBoard = systemBoardRef.id
        self.flowBoard = flowBoardRef.id
        self.componentBoard = componentBoardRef.id
    }
    
    public func pushName() async {
        logger.start()
        
        await self.pushName(captureHook: nil)
    }
    func pushName(captureHook: Hook?) async {
        // capture
        await captureHook?()
        guard id.isExist else {
            setIssue(Error.editorIsDeleted)
            logger.failure("ProjectEditor가 존재하지 않아 실행 취소됩니다.")
            return
        }
        guard self.nameInput.isEmpty == false else {
            setIssue(Error.nameInputIsEmpty)
            logger.failure("nameInput이 nil으로 비어있습니다.")
            return
        }
        
        guard self.nameInput != self.name else {
            setIssue(Error.pushWithSameValue)
            logger.failure("nameInput과 name이 동일합니다.")
            return
        }
        
        let projectSource = self.source
        let target = self.target
        let config = self.config
        let nameInput = self.nameInput
        
        
        // compute
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let projectSourceRef = await projectSource.ref else {
                    logger.failure("ProjectSouce를 찾을 수 없습니다")
                    return
                }
                guard let budServerRef = await config.budServer.ref else {
                    logger.failure("BudServer를 찾을 수 없습니다.")
                    return
                }
                guard let projectHubRef = await budServerRef.projectHub.ref else {
                    logger.failure("ProjectHub를 찾을 수 없습니다.")
                    return
                }
                
                await projectSourceRef.setName(nameInput)
                await projectHubRef.notifyNameChanged(target)
            }
        }
        
        logger.finished()
    }
    
    public func removeProject() async {
        logger.start()
        
        await self.removeProject(captureHook: nil)
    }
    func removeProject(captureHook: Hook?) async {
        // capture
        await captureHook?()
        guard id.isExist else { setIssue(Error.editorIsDeleted); return }
        let projectSource = self.source
        
        // compute
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let projectSourceRef = await projectSource.ref else { return }
                
                await projectSourceRef.remove()
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
        public var ref: ProjectEditor? {
            ProjectManager.container[self]
        }
    }
    public enum Error: String, Swift.Error {
        case editorIsDeleted
        case alreadySetUp
        case nameInputIsEmpty
        case pushWithSameValue
    }
}

// MARK: Object Manager
@MainActor @Observable
fileprivate final class ProjectManager: Sendable {
    // MARK: state
    fileprivate static var container: [ProjectEditor.ID: ProjectEditor] = [:]
    fileprivate static func register(_ object: ProjectEditor) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: ProjectEditor.ID) {
        container[id] = nil
    }
}
