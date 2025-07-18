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

private let logger = WorkFlow.getLogger(for: "ProjectModel")


// MARK: Object
@MainActor @Observable
public final class ProjectModel: Debuggable, EventDebuggable {
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
    nonisolated let id = ID()
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
        
    public var issue: (any Issuable)?
    package var callback: Callback?
    
    // MARK: action
    public func startUpdating() async {
        logger.start()
        
        await self.startUpdating(captureHook: nil)
    }
    func startUpdating(captureHook: Hook?) async {
        // capture
        await captureHook?()
        guard self.id.isExist else {
            setIssue(Error.projectModelIsDeleted)
            logger.failure("ProjectModel이 존재하지 않아 실행 취소됩니다.")
            return
        }
        
        let projectSource = self.source
        let projectModel = self.id
        
        // compute
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let projectSourceRef = await projectSource.ref else {
                    let log = logger.getLog("ProjectSource가 존재하지 않습니다. -> ProjectSource 삭제 로직 구현 필요")
                    logger.raw.fault("\(log)")
                    return
                }
                
                await projectSourceRef.setHandler(
                    .init({ event in
                        Task {
                            await WorkFlow {
                                guard let projectModelRef = await projectModel.ref else {
                                    return
                                }
                                
                                let updaterRef = projectModelRef.updaterRef
                                
                                await updaterRef.appendEvent(event)
                                await updaterRef.update()
                                
                                await projectModelRef.callback?()
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
        
        logger.finished()
    }
    
    public func removeProject() async {
        logger.start()
        
        await self.removeProject(captureHook: nil)
    }
    func removeProject(captureHook: Hook?) async {
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
    
    // TODO: 마지막 SystemModel의 Location에서 랜덤한 방향으로 시스템을 무작위로 생성
    public func createSystem() async {
        logger.start()
        
        await self.createSystem(captureHook: nil)
    }
    func createSystem(captureHook: Hook?) async {
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
    
    
    // MARK: value
    @MainActor
    public struct ID: Sendable, Hashable {
        public let value: UUID
        nonisolated init(value: UUID = UUID()) {
            self.value = value
        }
        
        var isExist: Bool {
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
