//
//  ProjectModel.swift
//  BudClient
//
//  Created by 김민우 on 7/16/25.
//
import Foundation
import Values
import Collections
import BudServer

private let logger = BudLogger("ProjectModel")


// MARK: Object
@MainActor @Observable
public final class ProjectModel: Debuggable, EventDebuggable, Hookable {
    
    
    // MARK: core
    init(config: Config<ProjectBoard.ID>,
         target: ProjectID,
         name: String,
         source: any ProjectSourceIdentity) {
        self.config = config
        self.target = target
        self.source = source
        self.updaterRef = Updater(owner: self.id)
        
        self.name = name
        self.nameInput = name
        
        ProjectModelManager.register(self)
    }
    func delete() {
        ProjectModelManager.unregister(self.id)
    }
    
    
    // MARK: state
    public nonisolated let id = ID()
    nonisolated let config: Config<ProjectBoard.ID>
    nonisolated let target: ProjectID
    nonisolated let source: any ProjectSourceIdentity
    nonisolated let updaterRef: Updater
    
    public internal(set) var name: String
    public var nameInput: String
    
    public internal(set) var systems = OrderedDictionary<SystemID, SystemModel.ID>()
    public internal(set) var workflows = OrderedDictionary<WorkflowID, WorkflowModel.ID>()
    public internal(set) var valueTypes = OrderedDictionary<ValueTypeID, ValueModel.ID>()
    public var systemLocations: Array<Location> {
        self.systems.values
            .compactMap { $0.ref }
            .map { $0.location }
    }
        
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
        guard self.id.isExist else {
            setIssue(Error.projectModelIsDeleted)
            logger.failure("ProjectModel이 존재하지 않아 실행 취소됩니다.")
            return
        }
        
        let projectSource = self.source
        let projectModel = self.id
        let me = ObjectID(self.id.value)
        
        // compute
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let projectSourceRef = await projectSource.ref else {
                    logger.failure("ProjectSource가 존재하지 않습니다. -> ProjectSource 삭제 로직 구현 필요")
                    return
                }
                
                await projectSourceRef.appendHandler(
                    for: me,
                    .init({ event in
                        Task {
                            guard let projectModelRef = await projectModel.ref else {
                                return
                            }
                            
                            let updaterRef = projectModelRef.updaterRef
                            
                            await updaterRef.appendEvent(event)
                            await updaterRef.update()
                            
                            await projectModelRef.callback?()
                            await projectModelRef.setCallbackNil()
                        }
                    }))
                
                await projectSourceRef.sendInitialEvents(to: me)
            }
        }
        
        // mutate
        
    }
    public func stopUpdating() async {
        logger.start()
        
        // capture
        await captureHook?()
        guard id.isExist else {
            setIssue(Error.projectModelIsDeleted)
            logger.failure("ProjectModel이 존재하지 않아 실행 취소됩니다.")
            return
        }
        
        logger.failure("미구현")
    }
    
    // pushName과 createFirstSystem에서 ProjectSource가 존재하지 않을 때
    public func pushName() async {
        logger.start()
        
        // capture
        await captureHook?()
        guard id.isExist else {
            setIssue(Error.projectModelIsDeleted)
            logger.failure("ProjectModel이 존재하지 않아 실행 취소됩니다.")
            return
        }
        guard self.nameInput.isEmpty == false else {
            setIssue(Error.nameInputIsEmpty)
            logger.failure("nameInput이 nil으로 비어있습니다.")
            return
        }
        
        guard self.nameInput != self.name else {
            setIssue(Error.pushWithSameValue)
            logger.failure("nameInput과 name이 동일합니다.")
            return
        }
        
        let projectSource = self.source
        let nameInput = self.nameInput
        
        
        // compute
        await computeHook?()
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let projectSourceRef = await projectSource.ref else {
                    logger.failure("ProjectSouce를 찾을 수 없습니다")
                    return
                }
                
                await projectSourceRef.setName(nameInput)
                await projectSourceRef.notifyNameChanged()
            }
        }
        
        logger.end()
    }
    public func createFirstSystem() async {
        logger.start()
        
        // capture
        await captureHook?()
        guard id.isExist else {
            setIssue(Error.projectModelIsDeleted)
            logger.failure("ProjectModel이 존재하지 않아 실행 취소됩니다.")
            return
        }
        guard systems.isEmpty else {
            setIssue(Error.firstSystemAlreadyExist)
            logger.failure("첫번째 System이 이미 존재합니다.")
            return
        }
        
        // compute
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let projectSourceRef = await self.source.ref else {
                    logger.failure("ProjectSource가 존재하지 않아 실행 취소됩니다.")
                    return
                }
                
                await projectSourceRef.createSystem()
            }
        }
    }
    
    public func removeProject() async {
        logger.start()
        
        // capture
        await captureHook?()
        guard id.isExist else {
            setIssue(Error.projectModelIsDeleted)
            logger.failure("ProjectModel이 존재하지 않아 실행 취소됩니다.")
            return
        }
        let projectSource = self.source
        
        // compute
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let projectSourceRef = await projectSource.ref else { return }
                
                await projectSourceRef.removeProject()
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
            ProjectModelManager.container[self] != nil
        }
        public var ref: ProjectModel? {
            ProjectModelManager.container[self]
        }
    }
    public enum Error: String, Swift.Error {
        case projectModelIsDeleted, projectSourceIsDeleted
        case nameInputIsEmpty, pushWithSameValue
        case firstSystemAlreadyExist
    }
}

// MARK: Object Manager
@MainActor @Observable
fileprivate final class ProjectModelManager: Sendable {
    // MARK: state
    fileprivate static var container: [ProjectModel.ID: ProjectModel] = [:]
    fileprivate static func register(_ object: ProjectModel) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: ProjectModel.ID) {
        container[id] = nil
    }
}
