//
//  ProjectModel.swift
//  BudClient
//
//  Created by 김민우 on 7/16/25.
//
import Foundation
import Values
import BudServer

private let logger = WorkFlow.getLogger(for: "ProjectModel")


// MARK: Object
@MainActor @Observable
public final class ProjectModel: Debuggable {
    // MARK: core
    init(config: Config<ProjectBoard.ID>,
         target: ProjectID,
         name: String,
         source: any ProjectSourceIdentity) {
        self.config = config
        self.target = target
        self.source = source
        self.updaterRef = Updater(parent: self.id)
        
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
    
    public internal(set) var systems: [SystemModel.ID] = []
    public internal(set) var workflows: [WorkflowModel.ID] = []
    public internal(set) var valueTypes: [ValueModel.ID] = []
        
    public var issue: (any Issuable)?
    
    
    // MARK: action
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
        let target = self.target
        let config = self.config
        let nameInput = self.nameInput
        
        
        // compute
        await withDiscardingTaskGroup { group in
            group.addTask {
                guard let projectSourceRef = await projectSource.ref else {
                    logger.failure("ProjectSouce를 찾을 수 없습니다")
                    return
                }
                guard let budServerRef = await config.budServer.ref else {
                    logger.failure("BudServer를 찾을 수 없습니다.")
                    return
                }
                guard let projectHubRef = await budServerRef.projectHub.ref else {
                    logger.failure("ProjectHub를 찾을 수 없습니다.")
                    return
                }
                
                await projectSourceRef.setName(nameInput)
                await projectHubRef.notifyNameChanged(target)
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
                
                await projectSourceRef.remove()
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
                
                await projectSourceRef.createFirstSystem()
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
