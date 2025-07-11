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
    public internal(set) var nameInput: String?
    public func setNameInput(_ value: String) {
        self.nameInput = value
        logger.success(value)
    }
    
    
    public var systemBoard: SystemBoard.ID?
    public var flowBoard: FlowBoard.ID?
    public var valueBoard: ValueBoard.ID?
    
    public var issue: (any Issuable)?
    
    
    // MARK: action
    public func setUp() async {
        await setUp(mutateHook: nil)
    }
    func setUp(mutateHook:Hook?) async {
        // mutate
        await mutateHook?()
        guard id.isExist else { setIssue(Error.editorIsDeleted); return }
        guard systemBoard == nil && flowBoard == nil && valueBoard == nil else { setIssue(Error.alreadySetUp); return }
        let myConfig = self.config.setParent(id)
        
        let systemBoardRef = SystemBoard(config: myConfig)
        let flowBoardRef = FlowBoard(config: myConfig)
        let valueBoardRef = ValueBoard(config: myConfig)
        
        self.systemBoard = systemBoardRef.id
        self.flowBoard = flowBoardRef.id
        self.valueBoard = valueBoardRef.id
    }
    
    public func pushName() async {
        await self.pushName(captureHook: nil)
    }
    func pushName(captureHook: Hook?) async {
        // capture
        await captureHook?()
        guard id.isExist else { setIssue(Error.editorIsDeleted); return }
        guard let nameInput else { setIssue(Error.nameInputIsNil); return}
        let projectSource = self.source
        let target = self.target
        let config = self.config
        
        
        // compute
        do {
            try await withThrowingDiscardingTaskGroup { group in
                group.addTask {
                    guard let projectSourceRef = await projectSource.ref else { return }
                    guard let budServerRef = await config.budServer.ref,
                          let projectHubRef = await budServerRef.projectHub.ref else { return }
                    
                    await projectSourceRef.setName(nameInput)
                    await projectHubRef.notifyNameChanged(target)
                }
            }
        } catch {
            logger.failure(error)
            setUnknownIssue(error); return
        }
        logger.success(nameInput)
    }
    
    public func removeProject() async {
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
        case nameInputIsNil
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
