//
//  GetterModel.swift
//  BudClient
//
//  Created by 김민우 on 7/7/25.
//
import Foundation
import Values
import Collections
import BudServer

private let logger = BudLogger("GetterModel")


// MARK: Object
@MainActor @Observable
public final class GetterModel: Debuggable, EventDebuggable, Hookable {
    // MARK: core
    init(config: Config<StateModel.ID>,
         diff: GetterSourceDiff) {
        self.target = diff.target
        self.config = config
        self.source = diff.id
        
        self.name = diff.name
        self.nameInput = diff.name
        
        self.updaterRef = Updater(owner: self.id)
        
        GetterModelManager.register(self)
    }
    func delete() {
        GetterModelManager.unregister(self.id)
    }
    
    
    // MARK: state
    nonisolated let id = ID()
    nonisolated let target: GetterID
    nonisolated let config: Config<StateModel.ID>
    nonisolated let source: any GetterSourceIdentity
    nonisolated let updaterRef: Updater
    var isUpdating: Bool = false
    
    public internal(set) var name: String
    public var nameInput: String
    
    public var parameters = OrderedDictionary<ParameterValue, ValueID>()
    public var parameterIndex: IndexSet = []
    
    public var result: ValueType = .anyValue
    
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
            setIssue(Error.getterModelIsDeleted)
            logger.failure("GetterModel이 존재하지 않아 실행 취소됩니다.")
            return
        }
        guard isUpdating == false else {
            setIssue(Error.alreadyUpdating)
            logger.failure("이미 업데이트 중입니다.")
            return
        }
        
        let getterSource = self.source
        let me = ObjectID(self.id.value)
        
        // compute
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let getterSourceRef = await getterSource.ref else {
                    logger.failure("GetterSource가 존재하지 않습니다.")
                    return
                }
                
                await getterSourceRef.appendHandler(
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
            setIssue(Error.getterModelIsDeleted)
            logger.failure("GetterModel이 존재하지 않아 실행 취소됩니다.")
            return
        }
        guard nameInput.isEmpty == false else {
            setIssue(Error.nameCannotBeEmpty)
            logger.failure("GetterModel의 name이 빈 문자열일 수 없습니다.")
            return
        }
        guard nameInput != name else {
            setIssue(Error.newNameIsSameAsCurrent)
            logger.failure("GetterModel의 name이 변경되지 않았습니다.")
            return
        }
        
        let source = self.source
        let nameInput = self.nameInput
        
        // compute
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let getterSourceRef = await source.ref else {
                    logger.failure("GetterSource가 존재하지 않습니다.")
                    return
                }
                
                await getterSourceRef.setName(nameInput)
                await getterSourceRef.notifyStateChanged()
            }
        }
    }
    public func pushParameterValues() async { }
    public func pushResult() async {
        
    }
    
    public func duplicateGetter() async {
        logger.start()
        
        // capture
        await captureHook?()
        guard id.isExist else {
            setIssue(Error.getterModelIsDeleted)
            logger.failure("GetterModel이 존재하지 않아 실행 취소됩니다.")
            return
        }
        let getterSource = self.source
        
        // compute
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let getterSourceRef = await getterSource.ref else {
                    logger.failure("GetterSource가 존재하지 않습니다.")
                    return
                }
                
                await getterSourceRef.duplicateGetter()
            }
        }
    }
    public func removeGetter() async {
        logger.start()
        
        // capture
        await captureHook?()
        guard id.isExist else {
            setIssue(Error.getterModelIsDeleted)
            logger.failure("GetterModel이 존재하지 않아 실행 취소됩니다.")
            return
        }
        let getterSource = self.source
        
        // compute
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let getterSourceRef = await getterSource.ref else {
                    logger.failure("GetterSource가 존재하지 않습니다.")
                    return
                }
                
                await getterSourceRef.removeGetter()
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
            GetterModelManager.container[self] != nil
        }
        public var ref: GetterModel? {
            GetterModelManager.container[self]
        }
    }
    public enum Error: String, Swift.Error {
        case getterModelIsDeleted
        case nameCannotBeEmpty, newNameIsSameAsCurrent
        case alreadyUpdating
    }
}


// MARK: Object Manager
@MainActor @Observable
fileprivate final class GetterModelManager: Sendable {
    // MARK: state
    fileprivate static var container: [GetterModel.ID: GetterModel] = [:]
    fileprivate static func register(_ object: GetterModel) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: GetterModel.ID) {
        container[id] = nil
    }
}
