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
        self.updater = SystemBoardUpdater(config: config.setParent(self.id))
        
        SystemBoardManager.register(self)
    }
    func delete() {
        SystemBoardManager.unregister(self.id)
    }
    
    // MARK: state
    nonisolated let id = ID()
    nonisolated let config: Config<ProjectEditor.ID>
    
    public internal(set) var models: [Location: SystemModel.ID] = [:]
    func isExist(_ target: SystemID) -> Bool {
        self.models.values.lazy
            .compactMap { $0.ref }
            .contains { $0.target == target }
    }
    func getSystemModel(_ target: SystemID) -> SystemModel.ID? {
        return models.values.first {
            $0.ref?.target == target
        }
    }
    
    var updater: SystemBoardUpdater
    
    public var issue: (any Issuable)?
    public var callback: Callback?
    
    
    // MARK: action
    public func subscribe() async {
        await self.subscribe(captureHook: nil)
    }
    func subscribe(captureHook: Hook?) async {
        // capture
        await captureHook?()
        guard id.isExist else { setIssue(Error.systemBoardIsDeleted); return }
        
        let projectEditorRef = config.parent.ref!
        let projectSource = projectEditorRef.source
        let me = ObjectID(id.value)
        let systemBoard = self.id
        let callback = self.callback
        
        // compute
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let projectSourceRef = await projectSource.ref else { return }
                let isSubscribed = await projectSourceRef.hasHandler(requester: me)
                guard isSubscribed == false else {
                    await systemBoard.ref?.setIssue(Error.alreadySubscribed)
                    return
                }
                
                await projectSourceRef.setHandler(
                    requester: me,
                    handler: .init({ event, workflow in
                        Task { @MainActor in
                            guard let updaterRef = systemBoard.ref?.updater else { return }
                            
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
        let me = ObjectID(id.value)
        let projectSource = self.config.parent.ref!.source
        
        // compute
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let projectSourceRef = await projectSource.ref else { return }
                
                await projectSourceRef.removeHandler(requester: me)
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
        let projectSource = self.config.parent.ref!.source
        
        // compute
        do {
            try await withThrowingDiscardingTaskGroup { group in
                group.addTask {
                    guard let projectSourceRef = await projectSource.ref else { return }
                    
                    try await projectSourceRef.createFirstSystem()
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
        case alreadySubscribed
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
