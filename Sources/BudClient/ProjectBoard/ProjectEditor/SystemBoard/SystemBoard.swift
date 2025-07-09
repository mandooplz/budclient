//
//  SystemBoard.swift
//  BudClient
//
//  Created by 김민우 on 7/6/25.
//
import Foundation
import Values
import BudServer


// MARK: Object
@MainActor @Observable
public final class SystemBoard: Sendable, Debuggable, EventDebuggable {
    // MARK: core
    init(config: Config<ProjectEditor.ID>) {
        self.config = config
        
        SystemBoardManager.register(self)
    }
    func delete() {
        SystemBoardManager.unregister(self.id)
    }
    
    // MARK: state
    nonisolated let id = ID()
    nonisolated let config: Config<ProjectEditor.ID>
    
    public internal(set) var models: Set<SystemModel.ID> = []
    var isModelsEmpty: Bool {
        models.isEmpty
    }
    func isExist(_ target: SystemID) -> Bool {
        self.models.lazy
            .compactMap { $0.ref }
            .contains { $0.target == target }
    }
    func getSystemModel(_ target: SystemID) -> SystemModel.ID? {
        self.models.first { $0.ref?.target == target }
    }
    
    var updater: SystemBoardUpdater.ID?
    
    public var issue: (any Issuable)?
    public var callback: Callback?
    
    
    // MARK: action
    public func setUp() async {
        await setUp(mutateHook: nil)
    }
    func setUp(mutateHook: Hook?) async {
        // captrue
        guard updater == nil else { setIssue(Error.alreadySetUp); return }
        
        // mutate
        await mutateHook?()
        guard id.isExist else { setIssue(Error.systemBoardIsDeleted); return }
        
        let myConfig = config.setParent(id)
        let updaterRef = SystemBoardUpdater(config: myConfig)
        self.updater = updaterRef.id
    }
    
    public func subscribe() async {
        await self.subscribe(captureHook: nil)
    }
    func subscribe(captureHook: Hook?) async {
        // capture
        await captureHook?()
        guard id.isExist else { setIssue(Error.systemBoardIsDeleted); return }
        
        let projectEditorRef = config.parent.ref!
        let projectSourceLink = projectEditorRef.sourceLink
        let project = projectEditorRef.target
        let me = ObjectID(id.value)
        let updater = self.updater
        let callback = self.callback
        
        // compute
        let ticket = SubscribeProjectSource(object: me, target: project)
        
        await withDiscardingTaskGroup { group in
            group.addTask {
                await projectSourceLink.setHandler(
                    ticket: ticket,
                    handler: .init({ event in
                        Task { @MainActor in
                            guard let updaterRef = updater?.ref else { return }
                            
                            updaterRef.queue.append(event)
                            await updaterRef.update()
                            
                            await callback?()
                        }
                    }))
            }
        }
    }
    
    public func unsubscribe() async {
        // capture
        let projectSourceLink = config.parent.ref!.sourceLink
        let me = ObjectID(id.value)
        
        // compute
        await withDiscardingTaskGroup { group in
            group.addTask {
                await projectSourceLink.removeHandler(object: me)
            }
        }
    }
    
    public func createFirstSystem() async {
        await self.createFirstSystem(captureHook: nil)
    }
    func createFirstSystem(captureHook: Hook?) async {
        // capture
        await captureHook?()
        guard id.isExist else { setIssue(Error.systemBoardIsDeleted); return }
        guard models.isEmpty else { setIssue(Error.systemAlreadyExist); return }
        let project = config.parent
        let projectSourceLink = project.ref!.sourceLink
        
        // compute
        do {
            try await withThrowingDiscardingTaskGroup { group in
                group.addTask {
                    try await projectSourceLink.createFirstSystem()
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
            SystemBoardManager.container[self] != nil
        }
        public var ref: SystemBoard? {
            SystemBoardManager.container[self]
        }
    }
    public enum Error: String, Swift.Error {
        case alreadySetUp
        case systemBoardIsDeleted
        case systemAlreadyExist
    }
}

// MARK: Object Manager
@MainActor @Observable
fileprivate final class SystemBoardManager: Sendable {
    // MARK: state
    fileprivate static var container: [SystemBoard.ID: SystemBoard] = [:]
    fileprivate static func register(_ object: SystemBoard) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: SystemBoard.ID) {
        container[id] = nil
    }
}
