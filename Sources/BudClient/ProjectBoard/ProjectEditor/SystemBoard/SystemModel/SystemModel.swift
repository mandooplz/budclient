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
         name: String,
         location: Location,
         source: any SystemSourceIdentity) {
        self.config = config
        self.target = target
        
        self.name = name
        self.nameInput = name
        self.location = location
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
    
    public internal(set) var name: String
    public var nameInput: String
    
    public var location: Location
    
    public var rootModel: RootModel.ID?
    public var objectModels: [ObjectModel.ID] = []
    
    var updater = SystemModelUpdater()
    
    public var issue: (any Issuable)?
    public var callback: Callback?
    
    
    // MARK: action
    public func subscribe() async {
        logger.start()
        
        await subscribe(captureHook: nil)
    }
    func subscribe(captureHook: Hook?) async {
        // capture
        await captureHook?()
        guard id.isExist else {
            setIssue(Error.systemModelIsDeleted)
            logger.failure("SystemModel이 존재하지 않아 실행 취소됩니다.")
            return
        }
        let systemSource = self.source
        let callback = self.callback
        let systemModel = self.id
        let me = ObjectID(id.value)
        
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let systemSourceRef = await systemSource.ref else {
                    logger.failure("SystemSource를 찾을 수 없습니다. ")
                    return
                }
                
                let isSubscribed = await systemSourceRef.hasHandler(requester: me)
                guard isSubscribed == false else {
                    await systemModel.ref?.setIssue(Error.alreadySubscribed);
                    logger.failure("이미 구독 중인 상태입니다.")
                    return
                }
                
                await systemSourceRef.setHandler(
                    requester: me,
                    handler: .init({ event in
                        Task {
                            await WorkFlow {
                                guard let updaterRef = await systemModel.ref?.updater else {
                                    logger.failure("SystemModel이 존재하지 않아 update가 취소됩니ㅏ.")
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
        guard id.isExist else {
            setIssue(Error.systemModelIsDeleted)
            logger.failure("SystemModel이 존재하지 않아 실행 취소됩니다.")
            return
        }
        guard name != nameInput else {
            setIssue(Error.noChangesToPush)
            logger.failure("nameInput과 name이 동일합니다.")
            return
        }
        let systemSource = self.source
        let nameInput = self.nameInput
        
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let systemSourceRef = await systemSource.ref else {
                    logger.failure("SystemSource가 존재하지 않아 update가 취소됩니다.")
                    return
                }
                
                await systemSourceRef.setName(nameInput)
                await systemSourceRef.notifyNameChanged()
            }
        }
    }
    
    public func addSystemRight() async {
        logger.start()
        
        await addSystemRight(captureHook: nil)
    }
    func addSystemRight(captureHook: Hook?) async {
        logger.start()
        
        // capture
        await captureHook?()
        guard id.isExist else {
            setIssue(Error.systemModelIsDeleted)
            logger.failure("SystemModel이 존재하지 않아 실행 취소됩니다.")
            return
        }
        guard let systemBoardRef = config.parent.ref,
              systemBoardRef.models[location.getRight()] == nil else {
                  setIssue(Error.systemAlreadyExist)
                  logger.failure("오른쪽에 시스템이 이미 존재합니다.")
                  return
        }
        
        let systemSource = self.source
        
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let systemSourceRef = await systemSource.ref else {
                    logger.failure("SystemSource가 존재하지 않아 실행 취소됩니다.")
                    return
                }
                
                await systemSourceRef.addSystemRight()
            }
        }
    }
    
    public func addSystemLeft() async {
        logger.start()
        
        await addSystemLeft(captureHook: nil)
    }
    func addSystemLeft(captureHook: Hook?) async {
        logger.start()
        
        // capture
        await captureHook?()
        guard id.isExist else {
            setIssue(Error.systemModelIsDeleted)
            logger.failure("SystemModel이 존재하지 않아 실행 취소됩니다.")
            return
        }
        guard let systemBoardRef = config.parent.ref,
              systemBoardRef.models[location.getLeft()] == nil else {
                  setIssue(Error.systemAlreadyExist)
                  logger.failure("왼쪽에 시스템이 이미 존재합니다.")
                  return
        }
        
        let systemSource = self.source
        
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let systemSourceRef = await systemSource.ref else { return }
                
                await systemSourceRef.addSystemLeft()
            }
        }
    }
    
    public func addSystemTop() async {
        await addSystemTop(captureHook: nil)
    }
    func addSystemTop(captureHook: Hook?) async {
        logger.start()
        
        // capture
        await captureHook?()
        guard id.isExist else {
            setIssue(Error.systemModelIsDeleted)
            logger.failure("SystemModel이 존재하지 않아 실행 취소됩니다.")
            return
        }
        guard let systemBoardRef = config.parent.ref,
              systemBoardRef.models[location.getTop()] == nil else {
                  setIssue(Error.systemAlreadyExist)
                  logger.failure("위쪽에 시스템이 이미 존재합니다.")
                  return
        }
        let systemSource = self.source
        
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let systemSourceRef = await systemSource.ref else {
                    logger.failure("SystemSource가 존재하지 않아 실행 취소됩니다.")
                    return
                }
                
                await systemSourceRef.addSystemTop()
            }
        }
    }
    
    public func addSystemBottom() async {
        await addSystemBottom(captureHook: nil)
    }
    func addSystemBottom(captureHook: Hook?) async {
        logger.start()
        
        // capture
        await captureHook?()
        guard id.isExist else {
            setIssue(Error.systemModelIsDeleted)
            logger.failure("SystemModel이 존재하지 않아 실행 취소됩니다.")
            return
        }
        guard let systemBoardRef = config.parent.ref,
              systemBoardRef.models[location.getBotttom()] == nil else {
                  setIssue(Error.systemAlreadyExist)
                  logger.failure("아래쪽에 시스템이 이미 존재합니다.")
                  return
        }
        let systemSource = self.source
        
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let systemSourceRef = await systemSource.ref else {
                    logger.failure("SystemSource가 존재하지 않아 실행 취소됩니다.")
                    return
                }
                
                await systemSourceRef.addSystemBottom()
            }
        }
    }
    
    public func createObjectModel() async {
        logger.start()
        
        await self.createObjectModel(mutateHook: nil)
    }
    func createObjectModel(mutateHook: Hook?) async {
        // mutate
        await mutateHook?()
        guard id.isExist else {
            setIssue(Error.systemModelIsDeleted)
            logger.failure("SystemModel이 존재하지 않아 실행 취소됩니다.")
            return
        }
        let systemSource = self.source
        
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let systemSourceRef = await systemSource.ref else {
                    logger.failure("SystemSource가 존재하지 않습니다.")
                    return
                }
                
                await systemSourceRef.createNewObject()
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
        guard id.isExist else {
            setIssue(Error.systemModelIsDeleted)
            logger.failure("SystemModel이 존재하지 않아 실행 취소됩니다.")
            return
        }
        let systemSource = self.source
        
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let systemSourceRef = await systemSource.ref else {
                    logger.failure("SystemSource가 존재하지 않아 실행 취소됩니다.")
                    return
                }
                
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
        case systemAlreadyExist // addSystem의 capture에서 검증
        case alreadySubscribed
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
