//
//  SystemModel.swift
//  BudClient
//
//  Created by 김민우 on 7/5/25.
//
import Foundation
import Values
import BudServer

private let logger = WorkFlow.getLogger(for: "SystemModel")


// MARK: Object
@MainActor @Observable
public final class SystemModel: Sendable, Debuggable, EventDebuggable {
    // MARK: core
    init(config: Config<SystemBoard.ID>,
         target: SystemID,
         source: any SystemSourceIdentity) {
        self.config = config
        self.target = target
        self.source = source
        
        SystemModelManager.register(self)
    }
    func delete() {
        SystemModelManager.unregister(self.id)
    }
    
    // MARK: state
    nonisolated let id = ID()
    nonisolated let config: Config<SystemBoard.ID>
    nonisolated let target: SystemID
    nonisolated let source: any SystemSourceIdentity
    
    public internal(set) var name: String?
    public var nameInput: String?
    
    public var location: Location?
    
    public var rootModel: RootModel.ID?
    public var objectModels: Set<ObjectModel.ID> = []
    
    var updater = SystemModelUpdater()
    
    public var issue: (any Issuable)?
    package var callback: Callback?
    
    
    // MARK: action
    public func subscribe() async {
        logger.start()
        
        await subscribe(captureHook: nil)
    }
    func subscribe(captureHook: Hook?) async {
        // capture
        await captureHook?()
        guard id.isExist else { setIssue(Error.systemModelIsDeleted); return }
        let systemSource = self.source
        let callback = self.callback
        let systemModel = self.id
        let me = ObjectID(id.value)
        
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let systemSourceRef = await systemSource.ref else { return }
                
                let isSubscribed = await systemSourceRef.hasHandler(requester: me)
                guard isSubscribed == false else {
                    await systemModel.ref?.setIssue(Error.alreadySubscribed);
                    return
                }
                
                await systemSourceRef.setHandler(
                    requester: me,
                    handler: .init({ event in
                        Task {
                            await WorkFlow {
                                guard let updaterRef = await systemModel.ref?.updater else { return }
                                
                                await updaterRef.appendEvent(event)
                                await updaterRef.update()
                                
                                await callback?()
                            }
                        }
                    }))
            }
        }
    }
    
    public func unsubscribe() async {
        logger.start()
        
        // capture
        let systemSource = self.source
        let me = ObjectID(id.value)
        
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let systemSourceRef = await systemSource.ref else { return }
                await systemSourceRef.removeHandler(requester: me)
            }
        }
    }
    
    public func pushName() async {
        logger.start()
        
        await self.pushName(captureHook: nil)
    }
    func pushName(captureHook: Hook?) async {
        // capture
        await captureHook?()
        guard id.isExist else { setIssue(Error.systemModelIsDeleted); return }
        guard let nameInput else { setIssue(Error.nameInputIsNil); return }
        guard name != nameInput else { setIssue(Error.noChangesToPush); return }
        let systemSource = self.source
        
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let systemSourceRef = await systemSource.ref else { return }
                
                await systemSourceRef.setName(nameInput)
                await systemSourceRef.notifyNameChanged()
            }
        }
    }
    
    func addSystemRight(captureHook: Hook?) async {
        logger.start()
        
        // capture
        await captureHook?()
        guard id.isExist else { setIssue(Error.systemModelIsDeleted); return }
        
        let systemSource = self.source
        
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let systemSourceRef = await systemSource.ref else { return }
                
                await systemSourceRef.addSystemRight()
            }
        }
    }
    func addSystemLeft(captureHook: Hook?) async {
        logger.start()
        
        // capture
        await captureHook?()
        guard id.isExist else { setIssue(Error.systemModelIsDeleted); return }
        let systemSource = self.source
        
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let systemSourceRef = await systemSource.ref else { return }
                
                await systemSourceRef.addSystemLeft()
            }
        }
    }
    func addSystemTop(captureHook: Hook?) async {
        logger.start()
        
        // capture
        await captureHook?()
        guard id.isExist else { setIssue(Error.systemModelIsDeleted); return }
        let systemSource = self.source
        
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let systemSourceRef = await systemSource.ref else { return }
                
                await systemSourceRef.addSystemTop()
            }
        }
    }
    func addSystemBottom(captureHook: Hook?) async {
        logger.start()
        
        // capture
        await captureHook?()
        guard id.isExist else { setIssue(Error.systemModelIsDeleted); return }
        let systemSource = self.source
        
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let systemSourceRef = await systemSource.ref else { return }
                
                await systemSourceRef.addSystemBottom()
            }
        }
    }
    
    public func remove() async {
        logger.start()
        
        await self.remove(captureHook: nil)
    }
    func remove(captureHook: Hook?) async {
        // capture
        await captureHook?()
        guard id.isExist else { setIssue(Error.systemModelIsDeleted); return}
        let systemSource = self.source
        
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let systemSourceRef = await systemSource.ref else { return }
                
                await systemSourceRef.remove()
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
        
        public var isExist: Bool {
            SystemModelManager.container[self] != nil
        }
        public var ref: SystemModel? {
            SystemModelManager.container[self]
        }
    }
    public enum Error: String, Swift.Error {
        case systemModelIsDeleted
        case systemAlreadyExist
        case alreadySubscribed
        case nameInputIsNil
        case noChangesToPush
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
