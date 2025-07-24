//
//  SetterModel.swift
//  BudClient
//
//  Created by 김민우 on 7/17/25.
//
import Foundation
import Values
import Collections
import BudServer

private let logger = BudLogger("SetterModel")


// MARK: Object
@MainActor @Observable
public final class SetterModel: Debuggable, EventDebuggable, Hookable {
    
    // MARK: core
    init(config: Config<StateModel.ID>,
         diff: SetterSourceDiff) {
        self.target = diff.target
        self.config = config
        self.source = diff.id
        
        self.name = diff.name
        self.nameInput = diff.name
        
        self.parameters = diff.parameters.toDictionary()
        self.parameterInput = diff.parameters
        
        self.updaterRef = Updater(owner: self.id)
        
        SetterModelManager.register(self)
    }
    func delete() {
        SetterModelManager.unregister(self.id)
    }
    
    
    // MARK: state
    nonisolated let id = ID()
    nonisolated let target: SetterID
    nonisolated let config: Config<StateModel.ID>
    nonisolated let updaterRef: Updater
    nonisolated let source: any SetterSourceIdentity
    var isUpdating: Bool = false
    
    public internal(set) var name: String
    public var nameInput: String
    
    public var parameters: OrderedDictionary<ParameterValue,ValueID>
    public var parameterInput: OrderedSet<ParameterValue>
    public var parameterIndex: IndexSet = []
    
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
            setIssue(Error.setterModelIsDeleted)
            logger.failure("SetterModel이 존재하지 않아 실행 취소됩니다.")
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
                guard let setterSourceRef = await source.ref else {
                    logger.failure("SetterSource가 존재하지 않습니다.")
                    return
                }
                
                await setterSourceRef.appendHandler(
                    requester: me,
                    .init({ event in
                        Task { [weak self] in
                            await self?.updaterRef.appendEvent(event)
                            await self?.updaterRef.update()
                            
                            await self?.callback?()
                        }
                    }))
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
            setIssue(Error.setterModelIsDeleted)
            logger.failure("SetterModel이 존재하지 않아 실행 취소됩니다.")
            return
        }
        
        
    }
    
    public func duplicateSetter() async {
        logger.start()
        
        // capture
        await captureHook?()
        guard id.isExist else {
            setIssue(Error.setterModelIsDeleted)
            logger.failure("SetterModel이 존재하지 않아 실행 취소됩니다.")
            return
        }
        let source = self.source
        
        // compute
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let setterSourceRef = await source.ref else {
                    logger.failure("SetterSource가 존재하지 않습니다.")
                    return
                }
                
                await setterSourceRef.duplicateSetter()
            }
        }
    }
    public func removeSetter() async {
        logger.start()
        
        // capture
        await captureHook?()
        guard id.isExist else {
            setIssue(Error.setterModelIsDeleted)
            logger.failure("SetterModel이 존재하지 않아 실행 취소됩니다.")
            return
        }
        
        let source = self.source
        
        // compute
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let setterSourceRef = await source.ref else {
                    logger.failure("SetterSource가 존재하지 않습니다.")
                    return
                }
                
                await setterSourceRef.removeSetter()
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
            SetterModelManager.container[self] != nil
        }
        public var ref: SetterModel? {
            SetterModelManager.container[self]
        }
    }
    public enum Error: String, Swift.Error {
        case setterModelIsDeleted
        case alreadyUpdating
        case nameCannotBeEmpty, newNameIsSameAsCurrent
    }
}


// MARK: Object Manager
@MainActor @Observable
fileprivate final class SetterModelManager: Sendable {
    // MARK: state
    fileprivate static var container: [SetterModel.ID: SetterModel] = [:]
    fileprivate static func register(_ object: SetterModel) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: SetterModel.ID) {
        container[id] = nil
    }
}

