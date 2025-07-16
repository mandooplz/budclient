//
//  SystemBoard.swift
//  BudClient
//
//  Created by 김민우 on 7/6/25.
//
import Foundation
import Values
import BudServer
import Collections

private let logger = WorkFlow.getLogger(for: "SystemBoard")


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
    
    public internal(set) var models = OrderedDictionary<Location,SystemModel.ID>()
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
        logger.start()
        
        await self.subscribe(captureHook: nil)
    }
    func subscribe(captureHook: Hook?) async {
        // capture
        await captureHook?()
        guard id.isExist else {
            setIssue(Error.systemBoardIsDeleted)
            logger.failure("SystemBoard가 존재하지 않아 실행 취소됩니다.")
            return
        }
        
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
                    logger.failure("SystemBoard에 이미 구독이 되어있습니다.")
                    return
                }
                
                await projectSourceRef.setHandler(
                    requester: me,
                    handler: .init({ event in
                        Task { @MainActor in
                            await WorkFlow {
                                guard let updaterRef = await systemBoard.ref?.updater else {
                                    logger.failure("SystemBoard가 존재하지 않아 update가 취소됩니다.")
                                    return
                                }
                                
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
        let me = ObjectID(id.value)
        let projectSource = self.config.parent.ref!.source
        
        // compute
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let projectSourceRef = await projectSource.ref else {
                    logger.failure("ProjectSource를 찾을 수 없어 실행 중단됩니다.")
                    return
                }
                
                await projectSourceRef.removeHandler(requester: me)
            }
        }
    }
    
    public func createFirstSystem() async {
        logger.start()
        
        await self.createFirstSystem(captureHook: nil)
    }
    func createFirstSystem(captureHook: Hook?) async {
        // capture
        await captureHook?()
        guard id.isExist else {
            setIssue(Error.systemBoardIsDeleted)
            logger.failure("SystemBoard가 존재하지 않아 실행 취소됩니다.")
            return
        }
        guard models.isEmpty else {
            setIssue(Error.systemAlreadyExist)
            logger.failure("첫번째 System이 이미 존재합니다.")
            return
        }
        let projectSource = self.config.parent.ref!.source // projectSource
        
        // compute
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let projectSourceRef = await projectSource.ref else { return }
                
                await projectSourceRef.createFirstSystem()
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
