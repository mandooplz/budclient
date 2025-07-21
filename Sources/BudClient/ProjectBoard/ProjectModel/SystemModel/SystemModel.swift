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
public final class SystemModel: Debuggable, EventDebuggable, Hookable {
    // MARK: core
    init(config: Config<ProjectModel.ID>,
         diff: SystemSourceDiff) {
        self.config = config
        self.target = diff.target
        self.source = diff.id
        self.updaterRef = Updater(owner: self.id)
        
        self.name = diff.name
        self.nameInput = diff.name
        self.location = diff.location
        
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
    nonisolated let updaterRef: Updater
    var isUpdating: Bool = false
    
    public internal(set) var name: String
    public var nameInput: String
    
    public internal(set) var location: Location
    
    public var root: ObjectModel.ID?
    public var objects = OrderedDictionary<ObjectID, ObjectModel.ID>()
    
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
            setIssue(Error.systemModelIsDeleted)
            logger.failure("SystemModel이 존재하지 않아 실행 취소됩니다.")
            return
        }
        guard isUpdating == false else {
            setIssue(Error.alreadyUpdating)
            logger.failure("이미 updating 중입니다.")
            return
        }
        let systemSource = self.source
        let me = ObjectID(self.id.value)
        
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let systemSourceRef = await systemSource.ref else {
                    logger.failure("SystemSource를 찾을 수 없습니다. ")
                    return
                }
                
                await systemSourceRef.setHandler(
                    for: me,
                    .init({ event in
                        Task { [weak self] in
                            await self?.updaterRef.appendEvent(event)
                            await self?.updaterRef.update()
                            
                            await self?.callback?()
                        }
                    }))
                
                await systemSourceRef.synchronize(requester: me)
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
            setIssue(Error.systemModelIsDeleted)
            logger.failure("SystemModel이 존재하지 않아 실행 취소됩니다.")
            return
        }
        guard nameInput.isEmpty == false else {
            setIssue(Error.nameCannotBeEmpty)
            logger.failure("SystemModel의 name이 빈 문자열일 수 없습니다.")
            return
        }
        guard name != nameInput else {
            setIssue(Error.newNameIsSameAsCurrent)
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
        
        // compute
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
        
        // compute
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let systemSourceRef = await systemSource.ref else { return }
                
                await systemSourceRef.addSystemLeft()
            }
        }
    }
    public func addSystemTop() async {
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
        
        // compute
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
        
        // compute
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
    
    public func createRootObject() async {
        logger.start()
        
        // capture
        await captureHook?()
        guard id.isExist else {
            setIssue(Error.systemModelIsDeleted)
            logger.failure("SystemModel이 존재하지 않아 실행 취소됩니다.")
            return
        }
        guard root == nil else {
            setIssue(Error.rootObjectModelAlreadyExist)
            logger.failure("RootObjectModel이 이미 존재합니다.")
            return
        }
        let source = self.source
        
        // compute
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let systemSourceRef = await source.ref else {
                    logger.failure("SystemSource가 존재하지 않아 실행 취소됩니다.")
                    return
                }
                
                await systemSourceRef.createRootObject()
            }
        }
    }
    
    public func removeSystem() async {
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
        case alreadyUpdating
        case nameCannotBeEmpty, newNameIsSameAsCurrent
        case systemAlreadyExist // addSystem의 capture에서 검증
        case rootObjectModelAlreadyExist
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
