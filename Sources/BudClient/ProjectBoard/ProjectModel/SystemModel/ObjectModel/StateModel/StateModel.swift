//
//  StateModel.swift
//  BudClient
//
//  Created by 김민우 on 7/7/25.
//
import Foundation
import Values
import Collections
import BudServer

private let logger = BudLogger("StateModel")


// MARK: Object
@MainActor @Observable
public final class StateModel: Debuggable, EventDebuggable, Hookable {
    // MARK: core
    init(config: Config<ObjectModel.ID>,
         diff: StateSourceDiff) {
        self.config = config
        self.target = diff.target
        self.updaterRef = Updater(owner: self.id)
        self.source = diff.id
        
        self.name = diff.name
        self.nameInput = diff.name
        
        self.accessLevel = diff.accessLevel
        self.accessLevelInput = diff.accessLevel
        
        self.stateValue = diff.stateValue
        self.stateValueInput = diff.stateValue
        
        StateModelManager.register(self)
    }
    func delete() {
        StateModelManager.unregister(self.id)
    }
    
    
    // MARK: state
    nonisolated let id = ID()
    nonisolated let config: Config<ObjectModel.ID>
    nonisolated let target: StateID
    nonisolated let source: any StateSourceIdentity
    nonisolated let updaterRef: Updater
    var isUpdating: Bool = false
    
    public internal(set) var name: String
    public var nameInput: String
    
    public internal(set) var accessLevel : AccessLevel
    public var accessLevelInput: AccessLevel
    
    public internal(set) var stateValue: StateValue
    public var stateValueInput: StateValue
    
    public internal(set) var getters = OrderedDictionary<GetterID,GetterModel.ID>()
    public internal(set) var setters = OrderedDictionary<SetterID, SetterModel.ID>()
    
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
            setIssue(Error.stateModelIsDeleted)
            logger.failure("StateModel이 존재하지 않아 실행 취소됩니다.")
            return
        }
        guard isUpdating == false else {
            setIssue(Error.alreadyUpdating)
            logger.failure("이미 업데이트 중입니다.")
            return
        }
        let stateSource = self.source
        let me = ObjectID(self.id.value)
        
        // compute
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let stateSourceRef = await stateSource.ref else {
                    logger.failure("StateSource가 존재하지 않습니다.")
                    return
                }
                
                await stateSourceRef.appendHandler(
                    requester: me,
                    .init({ event in
                        Task { [weak self] in
                            await self?.updaterRef.appendEvent(event)
                            await self?.updaterRef.update()
                            
                            await self?.callback?()
                        }
                    }))
                
                await stateSourceRef.registerSync(me)
                await stateSourceRef.synchronize()
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
            setIssue(Error.stateModelIsDeleted)
            logger.failure("StateModel이 존재하지 않아 실행 취소됩니다.")
            return
        }
        guard nameInput.isEmpty == false else {
            setIssue(Error.nameCannotBeEmpty)
            logger.failure("StateModel의 name이 빈 문자열일 수 없습니다.")
            return
        }
        guard nameInput != name else {
            setIssue(Error.newNameIsSameAsCurrent)
            logger.failure("StateModel의 name이 변경되지 않았습니다.")
            return
        }
        let stateSource = self.source
        let nameInput = self.nameInput
        
        // compute
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let stateSourceRef = await stateSource.ref else {
                    logger.failure("StateSource가 존재하지 않아 실행 취소됩니다.")
                    return
                }
                
                 await stateSourceRef.setName(nameInput)
                 await stateSourceRef.notifyStateChanged()
            }
        }
    }
    public func pushAccessLevel() async {
        logger.start()
        
        // capture
        await captureHook?()
        guard id.isExist else {
            setIssue(Error.stateModelIsDeleted)
            logger.failure("StateModel이 존재하지 않아 실행 취소됩니다.")
            return
        }
        guard accessLevelInput != accessLevel else {
            setIssue(Error.accessLevelIsSameAsCurrent)
            logger.failure("accessLevelInput이 기존 값과 동일합니다.")
            return
        }
        let stateSource = self.source
        let accessLevelInput = self.accessLevelInput
        
        // compute
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let stateSourceRef = await stateSource.ref else {
                    logger.failure("StateSource가 존재하지 않아 실행 취소됩니다.")
                    return
                }
                
                await stateSourceRef.setAccessLevel(accessLevelInput)
                await stateSourceRef.notifyStateChanged()
            }
        }

        
    }
    public func pushStateValue() async {
        logger.start()
        
        // capture
        await captureHook?()
        guard id.isExist else {
            setIssue(Error.stateModelIsDeleted)
            logger.failure("StateModel이 존재하지 않아 실행 취소됩니다.")
            return
        }
        guard stateValueInput != stateValue else {
            setIssue(Error.stateValueIsSameAsCurrent)
            logger.failure("stateValueInput이 기존 값과 동일합니다.")
            return
        }
        let stateSource = self.source
        let stateValueInput = self.stateValueInput
        
        // compute
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let stateSourceRef = await stateSource.ref else {
                    logger.failure("StateSource가 존재하지 않아 실행 취소됩니다.")
                    return
                }
                
                await stateSourceRef.setStateValue(stateValueInput)
                await stateSourceRef.notifyStateChanged()
            }
        }
    }

    public func appendNewGetter() async {
        logger.start()
        
        // capture
        await captureHook?()
        guard id.isExist else {
            setIssue(Error.stateModelIsDeleted)
            logger.failure("StateModel이 존재하지 않아 실행 취소됩니다.")
            return
        }
        let stateSource = self.source
        
        // compute
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let stateSourceRef = await stateSource.ref else {
                    logger.failure("StateSource가 존재하지 않습니다.")
                    return
                }
                
                await stateSourceRef.appendNewGetter()
            }
        }
        
    }
    public func appendNewSetter() async {
        logger.start()
        
        // capture
        await captureHook?()
        guard id.isExist else {
            setIssue(Error.stateModelIsDeleted)
            logger.failure("StateModel이 존재하지 않아 실행 취소됩니다.")
            return
        }
        let stateSource = self.source
        
        // compute
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let stateSourceRef = await stateSource.ref else {
                    logger.failure("StateSource가 존재하지 않습니다.")
                    return
                }
                
                await stateSourceRef.appendNewSetter()
            }
        }
    }
    
    public func duplicateState() async {
        logger.start()
        
        // capture
        await captureHook?()
        guard id.isExist else {
            setIssue(Error.stateModelIsDeleted)
            logger.failure("StateModel이 존재하지 않아 실행 취소됩니다.")
            return
        }
        let stateSource = self.source
        
        // compute
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let stateSourceRef = await stateSource.ref else {
                    logger.failure("StateSource가 존재하지 않습니다.")
                    return
                }
                
                await stateSourceRef.duplicateState()
            }
        }
    }
    
    public func removeState() async {
        logger.start()
        
        // capture
        await captureHook?()
        guard id.isExist else {
            setIssue(Error.stateModelIsDeleted)
            logger.failure("StateModel이 존재하지 않아 실행 취소됩니다.")
            return
        }
        let stateSource = self.source
        
        // compute
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let stateSourceRef = await stateSource.ref else {
                    logger.failure("StateSource가 존재하지 않습니다.")
                    return
                }
                
                await stateSourceRef.removeState()
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
            StateModelManager.container[self] != nil
        }
        public var ref: StateModel? {
            StateModelManager.container[self]
        }
    }
    public enum Error: String, Swift.Error {
        case stateModelIsDeleted
        case nameCannotBeEmpty, newNameIsSameAsCurrent
        case accessLevelIsSameAsCurrent, stateValueIsSameAsCurrent
        case alreadyUpdating
    }
}


// MARK: Objec Manager
@MainActor @Observable
fileprivate final class StateModelManager: Sendable {
    // MARK: state
    fileprivate static var container: [StateModel.ID: StateModel] = [:]
    fileprivate static func register(_ object: StateModel) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: StateModel.ID) {
        container[id] = nil
    }
}
