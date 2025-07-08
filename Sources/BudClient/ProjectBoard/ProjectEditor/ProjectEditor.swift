//
//  ProjectEditor.swift
//  BudClient
//
//  Created by 김민우 on 6/25/25.
//
import Foundation
import Values
import BudServer


// MARK: Object
@MainActor @Observable
public final class ProjectEditor: Debuggable, EventDebuggable {
    
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
    
    public var issue: (any Issuable)?
    package var callback: Callback?
    
    
    // MARK: action
    public func setUp() async {
        await setUp(mutateHook: nil)
    }
    func setUp(mutateHook:Hook?) async {
        // mutate
        await mutateHook?()
        guard id.isExist else { setIssue(Error.editorIsDeleted); return }
        guard systemBoard == nil, flowBoard == nil else { setIssue(Error.alreadySetUp); return }
        let myConfig = self.config.setParent(id)
        
        let systemBoardRef = SystemBoard(config: myConfig)
        let flowBoardRef = FlowBoard(config: myConfig)
        
        self.systemBoard = systemBoardRef.id
        self.flowBoard = flowBoardRef.id
    }
    
    public func push() async {
        await self.push(captureHook: nil)
    }
    func push(captureHook: Hook?) async {
        // capture
        await captureHook?()
        guard id.isExist else { setIssue(Error.editorIsDeleted); return }
        guard let name else { setIssue(Error.nameIsNil); return}
        let sourceLink = self.sourceLink
        
        // compute
        do {
            try await withThrowingDiscardingTaskGroup { group in
                group.addTask {
                    let editTicket = EditProjectSourceName(name)
                    
                    try await sourceLink.insert(editTicket)
                    try await sourceLink.editProjectName()
                }
            }
        } catch {
            setUnknownIssue(error); return
        }
    }
    
    public func removeProject() async {
        await self.removeProject(captureHook: nil)
    }
    func removeProject(captureHook: Hook?) async {
        // capture
        await captureHook?()
        guard id.isExist else { setIssue(Error.editorIsDeleted); return }
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
        public var ref: ProjectEditor? {
            ProjectManager.container[self]
        }
    }
    public enum Error: String, Swift.Error {
        case editorIsDeleted
        case alreadySetUp
        case nameIsNil
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
