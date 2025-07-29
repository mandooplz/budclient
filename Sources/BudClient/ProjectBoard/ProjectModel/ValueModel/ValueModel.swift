//
//  ValueModel.swift
//  BudClient
//
//  Created by 김민우 on 7/16/25.
//
import Foundation
import Values
import BudServer

private let logger = BudLogger("ValueModel")


// MARK: Object
@MainActor @Observable
public final class ValueModel: Debuggable, EventDebuggable, Hookable {
    // MARK: core
    init(config: Config<ProjectModel.ID>,
         diff: ValueSourceDiff) {
        self.config = config
        self.target = diff.target
        self.updaterRef = Updater(owner: self.id)
        self.source = diff.id
        
        self.createdAt = diff.createdAt
        self.updatedAt = diff.updatedAt
        self.order = diff.order
        
        self.name = diff.name
        self.nameInput = diff.name
        
        self.description = diff.description
        self.descriptionInput = diff.description
        
        self.fields = diff.fields
        self.fieldsInput = diff.fields
        
        ValueModelManager.register(self)
    }
    func delete() {
        ValueModelManager.unregister(self.id)
    }
    
    
    // MARK: state
    nonisolated let id = ID()
    nonisolated let config: Config<ProjectModel.ID>
    nonisolated let target: ValueID
    nonisolated let source: any ValueSourceIdentity
    nonisolated let updaterRef: Updater
    var isUpdating = false
    
    nonisolated let createdAt: Date
    var updatedAt: Date
    var order: Int
    
    public internal(set) var name: String
    public var nameInput: String
    
    public internal(set) var description: String?
    public var descriptionInput: String?
    
    public internal(set) var fields: [ValueField]
    public var fieldsInput: [ValueField]

    public var callback: Callback?
    public var issue: (any IssueRepresentable)?
    
    package var captureHook: Hook?
    package var computeHook: Hook?
    package var mutateHook: Hook?

    
    // MARK: action
    public func startUpdating() async {
        logger.start()
        
        // capture
        await captureHook?()
        guard id.isExist else {
            setIssue(Error.valueModelIsDeleted)
            logger.failure("ValueModel이 존재하지 않아 실행 취소됩니다.")
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
                guard let valueSourceRef = await source.ref else {
                    logger.failure("ValueSource가 존재하지 않습니다.")
                    return
                }
                
                await valueSourceRef.appendHandler(
                    requester: me,
                    .init { event in
                        Task { [weak self] in
                            await self?.updaterRef.appendEvent(event)
                            await self?.updaterRef.update()
                            
                            await self?.callback?()
                        }
                    }
                )
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
            setIssue(Error.valueModelIsDeleted)
            logger.failure("ValueModel이 존재하지 않아 실행 취소됩니다.")
            return
        }
    }
    public func pushDescription() async {
        logger.start()
        
        // capture
        await captureHook?()
        guard id.isExist else {
            setIssue(Error.valueModelIsDeleted)
            logger.failure("ValueModel이 존재하지 않아 실행 취소됩니다.")
            return
        }
    }
    public func pushFields() async {
        logger.start()
        
        // capture
        await captureHook?()
        guard id.isExist else {
            setIssue(Error.valueModelIsDeleted)
            logger.failure("ValueModel이 존재하지 않아 실행 취소됩니다.")
            return
        }
    }
    
    public func removeValue() async {
        logger.start()
        
        // capture
        await captureHook?()
        guard id.isExist else {
            setIssue(Error.valueModelIsDeleted)
            logger.failure("ValueModel이 존재하지 않아 실행 취소됩니다.")
            return
        }
        let source = self.source
        
        // compute
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let valueSourceRef = await source.ref else {
                    logger.failure("ValueSource가 존재하지 않습니다.")
                    return
                }
                
                await valueSourceRef.removeValue()
            }
        }
    }
    
    
    // MARK: value
    @MainActor
    public struct ID: Sendable, Hashable {
        public let value = UUID()
        nonisolated init() { }
        
        public var isExist: Bool {
            ValueModelManager.container[self] != nil
        }
        public var ref: ValueModel? {
            ValueModelManager.container[self]
        }
    }
    public enum Error: String, Swift.Error {
        case valueModelIsDeleted
        case alreadyUpdating
    }
}



// MARK: ObjectManager
@MainActor @Observable
fileprivate final class ValueModelManager: Sendable {
    // MARK: state
    fileprivate static var container: [ValueModel.ID: ValueModel] = [:]
    fileprivate static func register(_ object: ValueModel) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: ValueModel.ID) {
        container[id] = nil
    }
}

