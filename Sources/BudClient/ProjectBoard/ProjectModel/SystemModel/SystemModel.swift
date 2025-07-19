//
//  SystemModel.swift
//  BudClient
//
//  Created by 김민우 on 7/5/25.
//
import Foundation
import Values
import BudServer
import Collections

private let logger = BudLogger("SystemModel")


// MARK: Object
@MainActor @Observable
public final class SystemModel: Sendable, Debuggable, EventDebuggable {
    // MARK: core
    init(config: Config<ProjectModel.ID>,
         target: SystemID,
         name: String,
         location: Location,
         source: any SystemSourceIdentity) {
        self.config = config
        self.target = target
        self.source = source
        self.updater = Updater(owner: self.id)
        
        self.name = name
        self.nameInput = name
        self.location = location
        
        SystemModelManager.register(self)
    }
    func delete() {
        SystemModelManager.unregister(self.id)
    }
    
    // MARK: state
    nonisolated let id = ID()
    nonisolated let config: Config<ProjectModel.ID>
    nonisolated let target: SystemID
    nonisolated let source: any SystemSourceIdentity
    nonisolated let updater: Updater
    
    public internal(set) var name: String
    public var nameInput: String
    
    public internal(set) var location: Location
    
    public var root: ObjectModel.ID?
    public var objects = OrderedDictionary<ObjectID, ObjectModel.ID>()
    
    public var issue: (any IssueRepresentable)?
    public var callback: Callback?
    
    
    // MARK: action
    public func startUpdating() async {
        logger.start()
        
        await startUpdating(captureHook: nil)
    }
    func startUpdating(captureHook: Hook?) async {
        // capture
        await captureHook?()
        guard id.isExist else {
            setIssue(Error.systemModelIsDeleted)
            logger.failure("SystemModel이 존재하지 않아 실행 취소됩니다.")
            return
        }
        let systemSource = self.source
        let systemModel = self.id
        
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let systemSourceRef = await systemSource.ref else {
                    logger.failure("SystemSource를 찾을 수 없습니다. ")
                    return
                }
                
                await systemSourceRef.setHandler(
                    .init({ event in
                        Task {
                            await WorkFlow {
                                guard let updaterRef = await systemModel.ref?.updater else {
                                    logger.failure("SystemModel이 존재하지 않아 update가 취소됩니다.")
                                    return
                                }
                                
                                await updaterRef.appendEvent(event)
                                await updaterRef.update()
                                
                                await systemModel.ref?.callback?()
                                await systemModel.ref?.setCallbackNil()
                            }
                        }
                    }))
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
        guard let projectModelRef = config.parent.ref,
              projectModelRef.systemLocations.contains(location.getRight()) == false else {
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
        guard let projectModelRef = config.parent.ref,
              projectModelRef.systemLocations.contains(location.getLeft()) == false else {
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
        guard let projectModelRef = config.parent.ref,
              projectModelRef.systemLocations.contains(location.getTop()) == false else {
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
        guard let projectModelRef = config.parent.ref,
              projectModelRef.systemLocations.contains(location.getBotttom()) == false else {
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
    
    // TODO: Root에 해당하는 Object를 생성
    public func createRoot() async {
        logger.start()
        
        await self.createRoot(captureHook: nil)
    }
    func createRoot(captureHook: Hook?) async {
        await captureHook?()
        guard id.isExist else {
            setIssue(Error.systemModelIsDeleted)
            logger.failure("SystemModel이 존재하지 않아 실행 취소됩니다.")
            return
        }
        let source = self.source
        
        // compute
        await withDiscardingTaskGroup { group in
            group.addTask {
                if let systemSourceRef = await source.ref {
                    await systemSourceRef.createRoot()
                } else {
                    logger.failure("SystemSource가 존재하지 않아 실행 취소됩니다. -> 추후 정리 로직 구현 예정")
                    return
                }
            }
        }
    }
    
    public func removeSystem() async {
        logger.start()
        
        await self.removeSystem(captureHook: nil)
    }
    func removeSystem(captureHook: Hook?) async {
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
                
                await systemSourceRef.removeSystem()
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
