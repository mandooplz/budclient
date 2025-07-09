//
//  SystemModel.swift
//  BudClient
//
//  Created by 김민우 on 7/5/25.
//
import Foundation
import Values
import BudServer


// MARK: Object
@MainActor @Observable
public final class SystemModel: Sendable, Debuggable, EventDebuggable {
    // MARK: core
    init(config: Config<SystemBoard.ID>,
         target: SystemID,
         sourceLink: SystemSourceLink) {
        self.config = config
        self.target = target
        self.sourceLink = sourceLink
        
        SystemModelManager.register(self)
    }
    func delete() {
        SystemModelManager.unregister(self.id)
    }
    
    // MARK: state
    nonisolated let id = ID()
    nonisolated let config: Config<SystemBoard.ID>
    nonisolated let target: SystemID
    nonisolated let sourceLink: SystemSourceLink
    
    public var name: String? 
    public var location: Location?
    
    public var rootModel: RootModel.ID?
    public var objectModels: Set<ObjectModel.ID> = []
    
    var updater = SystemModelUpdater()
    
    public var issue: (any Issuable)?
    package var callback: Callback?
    
    
    // MARK: action
    public func subscribe() async {
        await subscribe(captureHook: nil)
    }
    func subscribe(captureHook: Hook?) async {
        // capture
        await captureHook?()
        guard id.isExist else { setIssue(Error.systemModelIsDeleted); return }
        let callback = self.callback
        let sourceLink = self.sourceLink
        let systemModel = self.id
        let me = ObjectID(id.value)
        
        await withDiscardingTaskGroup { group in
            group.addTask {
                await sourceLink.setHandler(
                    requester: me,
                    handler: .init({ event in
                        Task { @MainActor in
                            guard let updaterRef = systemModel.ref?.updater else { return }
                            
                            updaterRef.appendEvent(event)
                            updaterRef.update()
                            
                            await callback?()
                        }
                    }))
            }
        }
    }
    
    public func unsubscribe() async {
        // capture
        let sourceLink = self.sourceLink
        let me = ObjectID(id.value)
        
        await withDiscardingTaskGroup { group in
            group.addTask {
                await sourceLink.removeHandler(requester: me)
            }
        }
    }
    
    public func pushName() async {
        await self.pushName(captureHook: nil)
    }
    func pushName(captureHook: Hook?) async {
        // capture
        await captureHook?()
        guard id.isExist else { setIssue(Error.systemModelIsDeleted); return}
        guard let name else { setIssue(Error.nameIsNil); return}
        let sourceLink = self.sourceLink
    }
    
    func addSystemRight(captureHook: Hook?) async {
        // capture
        await captureHook?()
        guard id.isExist else { setIssue(Error.systemModelIsDeleted); return }
        let systemBoardRef = self.config.parent.ref
        let sourceLink = self.sourceLink
    }
    func addSystemLeft(captureHook: Hook?) async {
        // capture
        await captureHook?()
        guard id.isExist else { setIssue(Error.systemModelIsDeleted); return }
        let sourceLink = self.sourceLink
    }
    func addSystemTop(captureHook: Hook?) async {
        // capture
        await captureHook?()
        guard id.isExist else { setIssue(Error.systemModelIsDeleted); return }
        let sourceLink = self.sourceLink
    }
    func addSystemBottom(captureHook: Hook?) async {
        // capture
        await captureHook?()
        guard id.isExist else { setIssue(Error.systemModelIsDeleted); return }
        let sourceLink = self.sourceLink
    }
    
    public func remove() async {
        await self.remove(captureHook: nil)
    }
    func remove(captureHook: Hook?) async {
        // capture
        await captureHook?()
        guard id.isExist else { setIssue(Error.systemModelIsDeleted); return}
        let sourceLink = self.sourceLink
        
        await withDiscardingTaskGroup { group in
            group.addTask {
                await sourceLink.remove()
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
            SystemModelManager.container[self] != nil
        }
        public var ref: SystemModel? {
            SystemModelManager.container[self]
        }
    }
    public enum Error: String, Swift.Error {
        case systemModelIsDeleted
        case systemAlreadyExist
        case nameIsNil
    }
}

// MARK: Object Manager
@MainActor @Observable
fileprivate final class SystemModelManager: Sendable {
    fileprivate static var container: [SystemModel.ID: SystemModel] = [:]
    fileprivate static func register(_ object: SystemModel) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: SystemModel.ID) {
        container[id] = nil
    }
}
