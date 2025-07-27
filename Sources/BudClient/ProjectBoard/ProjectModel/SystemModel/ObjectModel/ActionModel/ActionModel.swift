//
//  ActionModel.swift
//  BudClient
//
//  Created by 김민우 on 7/7/25.
//
import Foundation
import Values
import BudServer

private let logger = BudLogger("ActionModel")


// MARK: Object
@MainActor @Observable
public final class ActionModel: Debuggable, EventDebuggable, Hookable {
    // MARK: core
    init(config: Config<ObjectModel.ID>,
         diff: ActionSourceDiff) {
        self.config = config
        self.target = diff.target
        self.source = diff.id
        
        self.name = diff.name
        self.nameInput = diff.name
        
        self.updaterRef = Updater(owner: self.id)
        
        ActionModelManager.register(self)
    }
    func delete() {
        ActionModelManager.unregister(self.id)
    }
    
    
    // MARK: state
    nonisolated let id = ID()
    nonisolated let config: Config<ObjectModel.ID>
    nonisolated let target: ActionID
    nonisolated let updaterRef: Updater
    nonisolated let source: any ActionSourceIdentity
    
    var isUpdating: Bool = false
    
    public internal(set) var name: String
    public var nameInput: String
    
    public var issue: (any IssueRepresentable)?
    public var callback: Callback?
    
    package var captureHook: Hook?
    package var computeHook: Hook?
    package var mutateHook: Hook?
    
    
    // MARK: action
    public func startUpdating() async {
        logger.start()
        
        // capture
        await captureHook?()
        guard id.isExist else {
            setIssue(Error.actionModelIsDeleted)
            logger.failure("ActionModel이 존재하지 않아 실행 취소됩니다.")
            return
        }
        guard isUpdating == false else {
            setIssue(Error.alreadyUpdating)
            logger.failure("이미 업데이트 중입니다.")
            return
        }
        let source = self.source
        let me = ObjectID(self.id.value)
        
        // compute
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let actionSourceRef = await source.ref else {
                    logger.failure("ActionSource가 존재하지 않습니다.")
                    return
                }
                
                await actionSourceRef.appendHandler(
                    requester: me,
                    .init { event in
                        Task { [weak self] in
                            await self?.updaterRef.appendEvent(event)
                            await self?.updaterRef.update()
                            
                            await self?.callback?()
                        }
                    })
            }
        }
        
        // mutate
        self.isUpdating = true
    }
    
    public func pushName() async {
        logger.start()
        
        // capture
        await captureHook?()
        guard id.isExist else {
            setIssue(Error.actionModelIsDeleted)
            logger.failure("ActionModel이 존재하지 않아 실행 취소됩니다.")
            return
        }
        guard nameInput.isEmpty == false else {
            setIssue(Error.nameCannotBeEmpty)
            logger.failure("ActionModel의 name이 빈 문자열일 수 없습니다.")
            return
        }
        guard nameInput != name else {
            setIssue(Error.newNameIsSameAsCurrent)
            logger.failure("ActionModel의 name이 변경되지 않았습니다.")
            return
        }
        let source = self.source
        let nameInput = self.nameInput
        
        // compute
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let actionSourceRef = await source.ref else {
                    logger.failure("ActionSource가 존재하지 않습니다.")
                    return
                }
                
                await actionSourceRef.setName(nameInput)
                await actionSourceRef.notifyStateChanged()
            }
        }
        
    }
    
    public func duplicateAction() async {
        logger.start()
        
        // capture
        await captureHook?()
        guard id.isExist else {
            setIssue(Error.actionModelIsDeleted)
            logger.failure("ActionModel이 존재하지 않아 실행 취소됩니다.")
            return
        }
        let source = self.source
        
        // compute
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let actionSourceRef = await source.ref else {
                    logger.failure("ActionSource가 존재하지 않습니다.")
                    return
                }
                
                await actionSourceRef.duplicateAction()
            }
        }
    }
    public func removeAction() async {
        logger.start()
        
        // capture
        await captureHook?()
        guard id.isExist else {
            setIssue(Error.actionModelIsDeleted)
            logger.failure("ActionModel이 존재하지 않아 실행 취소됩니다.")
            return
        }
        let source = self.source
        
        // compute
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let actionSourceRef = await source.ref else {
                    logger.failure("ActionSource가 존재하지 않습니다.")
                    return
                }
                
                await actionSourceRef.removeAction()
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
            ActionModelManager.container[self] != nil
        }
        public var ref: ActionModel? {
            ActionModelManager.container[self]
        }
    }
    public enum Error: String, Swift.Error {
        case actionModelIsDeleted
        case nameCannotBeEmpty, newNameIsSameAsCurrent
        case alreadyUpdating
    }
}


// MARK: Object Manager
@MainActor @Observable
fileprivate final class ActionModelManager: Sendable {
    // MARK: state
    fileprivate static var container: [ActionModel.ID: ActionModel] = [:]
    fileprivate static func register(_ object: ActionModel) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: ActionModel.ID) {
        container[id] = nil
    }
}
