//
//  ProjectBoard.swift
//  BudClient
//
//  Created by 김민우 on 6/25/25.
//
import Foundation
import Values
import BudServer
import os


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
    public func isEditorExist(target: ProjectID) -> Bool {
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
                let projectHubLink = await config.budServerLink.getProjectHub()
                let ticket = SubscribeProjectHub(object: me,user: config.user)
                
                await projectHubLink.setHandler(
                    ticket: ticket,
                    handler: .init({ event in
                        Task { @MainActor in
                            guard let updaterRef = projectBoard.ref?.updater else { return }
                            
                            updaterRef.appendEvent(event)
                            await updaterRef.update()
                            
                            await callback?()
                        }
                    })
                )
            }
        }
    }
    
    public func unsubscribe() async {
        // capture
        let config = self.config
        let me = ObjectID(id.value)
        
        // compute
        await withDiscardingTaskGroup { group in
            group.addTask {
                let projectHubLink = await config.budServerLink.getProjectHub()
                await projectHubLink.removeHandler(object: me)
            }
        }
    }
    
    public func createProject() async {
        await self.createProject(captureHook: nil)
    }
    func createProject(captureHook: Hook?) async {
        // capture
        await captureHook?()
        guard id.isExist else { setIssue(Error.projectBoardIsDeleted); return }
        let config = self.config
        let budServerLink = config.budServerLink
        
        
        // compute
        do {
            try await withThrowingDiscardingTaskGroup { group in
                group.addTask {
                    let newProject = ProjectID()
                    let newName = "Project \(Int.random(in: 1..<1000))"
                    
                    async let ticket = CreateProjectSource(
                        creator: config.user,
                        target: newProject,
                        name: newName)
                    
                    async let projectHubLink = await budServerLink.getProjectHub()
                    
                    await projectHubLink.insertTicket(ticket)
                    try await projectHubLink.createProjectSource()
                }
            }
        } catch {
            setUnknownIssue(error); return
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

