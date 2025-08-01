//
//  ObjectModel.swift
//  BudClient
//
//  Created by 김민우 on 7/4/25.
//
import Foundation
import Values
import BudServer
import Collections

private let logger = BudLogger("ObjectModel")


// MARK: Object
@MainActor @Observable
public final class ObjectModel: Debuggable, EventDebuggable, Hookable {
    // MARK: core
    init(config: Config<SystemModel.ID>,
         diff: ObjectSourceDiff) {
        self.target = diff.target
        self.source = diff.id
        self.config = config
        self.updaterRef = Updater(owner: self.id)
        
        self.role = diff.role
        self.parent = diff.parent
        self.childs = diff.childs
        self.name = diff.name
        self.nameInput = diff.name
        
        ObjectModelManager.register(self)
    }
    func delete() {
        ObjectModelManager.unregister(self.id)
    }
    
    
    // MARK: state
    nonisolated let id = ID()
    nonisolated let config: Config<SystemModel.ID>
    nonisolated let target: ObjectID
    nonisolated let source: any ObjectSourceIdentity
    nonisolated let updaterRef: Updater
    var isUpdating: Bool = false
    
    public internal(set) var name: String
    public var nameInput: String
    
    public nonisolated let role: ObjectRole
    public internal(set) var parent: ObjectID!
    public internal(set) var childs: OrderedSet<ObjectID> = []
    
    public internal(set) var states = OrderedDictionary<StateID, StateModel.ID>()
    public internal(set) var actions = OrderedDictionary<ActionID, ActionModel.ID>()
    
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
            setIssue(Error.objectModelIsDeleted)
            logger.failure("ObjectModel이 존재하지 않아 실행 취소됩니다.")
            return
        }
        guard isUpdating == false else {
            setIssue(Error.alreadyUpdating)
            logger.failure("이미 updating 중입니다.")
            return
        }
        let objectSource = self.source
        let me = ObjectID(self.id.value)
        
        // compute
        await computeHook?()
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let objectSourceRef = await objectSource.ref else {
                    logger.failure("ObjectSource가 존재하지 않습니다.")
                    return
                }
                
                await objectSourceRef.appendHandler(
                    requester: me,
                    .init { event in
                        Task { [weak self] in
                            await self?.updaterRef.appendEvent(event)
                            await self?.updaterRef.update()
                            
                            await self?.callback?()
                        }
                    })
                
                await objectSourceRef.registerSync(me)
                await objectSourceRef.synchronize()
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
            setIssue(Error.objectModelIsDeleted)
            logger.failure("ObjectModel이 존재하지 않아 실행 취소됩니다.")
            return
        }
        guard nameInput.isEmpty == false else {
            setIssue(Error.nameCannotBeEmpty)
            logger.failure("name이 빈 문자열일 수는 없습니다.")
            return
        }
        guard nameInput != name else {
            setIssue(Error.newNameIsSameAsCurrent)
            logger.failure("nameInput이 name과 동일합니다.")
            return
        }
        
        let objectSource = self.source
        let nameInput = self.nameInput
        
        // compute
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let objectSourceRef = await objectSource.ref else {
                    logger.failure("ObjectSource가 존재하지 않습니다.")
                    return
                }
                
                await objectSourceRef.setName(nameInput)
                await objectSourceRef.notifyStateChanged()
            }
        }
        
    }
    
    public func createChildObject() async {
        logger.start()
        
        // capture
        await captureHook?()
        guard id.isExist else {
            setIssue(Error.objectModelIsDeleted)
            logger.failure("ObjectModel이 존재하지 않아 실행 취소됩니다.")
            return
        }
        
        let objectSource = self.source
        
        // compute
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let objectSourceRef = await objectSource.ref else {
                    logger.failure("ObjectSource가 존재하지 않아 실행 취소됩니다.")
                    return
                }
                
                await objectSourceRef.createChildObject()
            }
        }
    }
    
    public func appendNewState() async {
        logger.start()
        
        // capture
        await captureHook?()
        guard id.isExist else {
            setIssue(Error.objectModelIsDeleted)
            logger.failure("ObjectModel이 존재하지 않아 실행 취소됩니다.")
            return
        }
        let objectSource = self.source
        
        // compute
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let objectSourceRef = await objectSource.ref else {
                    logger.failure("ObjectSource가 존재하지 않아 실행 취소됩니다.")
                    return
                }
                
                await objectSourceRef.appendNewState()
            }
        }
    }
    public func appendNewAction() async {
        logger.start()
        
        // capture
        await captureHook?()
        guard id.isExist else {
            setIssue(Error.objectModelIsDeleted)
            logger.failure("ObjectModel이 존재하지 않아 실행 취소됩니다.")
            return
        }
        
        let objectSource = self.source
        
        // compute
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let objectSourceRef = await objectSource.ref else {
                    logger.failure("ObjectSource가 존재하지 않아 실행 취소됩니다.")
                    return
                }
                
                await objectSourceRef.appendNewAction()
            }
        }
    }
    
    public func removeObject() async {
        logger.start()
        
        // capture
        await captureHook?()
        guard id.isExist else {
            setIssue(Error.objectModelIsDeleted)
            logger.failure("ObjectModel이 존재하지 않아 실행 취소됩니다.")
            return
        }
        let objectSource = self.source
        
        // compute
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let objectSourceRef = await objectSource.ref else {
                    logger.failure("ObjectSource가 존재하지 않아 실행 취소됩니다.")
                    return
                }
                
                await objectSourceRef.removeObject()
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
            ObjectModelManager.container[self] != nil
        }
        public var ref: ObjectModel? {
            ObjectModelManager.container[self]
        }
    }
    public enum Error: String, Swift.Error {
        case objectModelIsDeleted
        case alreadyUpdating
        case nameCannotBeEmpty, newNameIsSameAsCurrent
    }
}


// MARK: Object Manager
@MainActor @Observable
fileprivate final class ObjectModelManager: Sendable {
    fileprivate static var container: [ObjectModel.ID: ObjectModel] = [:]
    fileprivate static func register(_ object: ObjectModel) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: ObjectModel.ID) {
        container[id] = nil
    }
}
