//
//  RootModel.swift
//  BudClient
//
//  Created by 김민우 on 7/9/25.
//
import Foundation
import Values
import BudServer

private let logger = WorkFlow.getLogger(for: "SystemModel")


// MARK: Object
@MainActor @Observable
public final class RootModel: Sendable, Debuggable {
    // MARK: core
    init(name: String,
         target: ObjectID,
         config: Config<SystemModel.ID>) {
        self.name = name
        self.nameInput = name
        
        self.target = target
        self.config = config
        
        RootModelManager.register(self)
    }
    func delete() {
        RootModelManager.unregister(self.id)
    }
    
    
    // MARK: state
    nonisolated let id = ID()
    nonisolated let config: Config<SystemModel.ID>
    nonisolated let target: ObjectID
    
    public internal(set) var name: String
    public var nameInput: String
    
    public var states: [RootState.ID] = []
    public var actions: [RootAction.ID] = []
    
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
            setIssue(Error.rootModelIsDeleted)
            logger.failure("RootModel이 삭제되어 실행 취소됩니다.")
            return
        }
        
        logger.failure("미구현")
    }
    
    public func createAction() async {
        logger.start()
        
        await self.createAction(captureHook: nil)
    }
    func createAction(captureHook: Hook?) async {
        // capture
        await captureHook?()
        guard id.isExist else {
            setIssue(Error.rootModelIsDeleted)
            logger.failure("RootModel이 삭제되어 실행 취소됩니다.")
            return
        }
    }
    
    public func createState() async {
        logger.start()
        
        await self.createState(captureHook: nil)
    }
    func createState(captureHook: Hook?) async {
        // capture
        guard id.isExist else {
            setIssue(Error.rootModelIsDeleted)
            logger.failure("RootModel이 삭제되어 실행 취소됩니다.")
            return
        }
    }
    
    
    // MARK: value
    @MainActor
    public struct ID: Sendable, Hashable {
        let value: UUID
        nonisolated init(value: UUID = UUID()) {
            self.value = value
        }
        
        var isExist: Bool {
            false
        }
        public var ref: RootModel? {
            nil
        }
    }
    public enum Error: String, Swift.Error {
        case rootModelIsDeleted
    }
}


// MARK: ObjectManager
@MainActor @Observable
fileprivate final class RootModelManager: Sendable {
    // MARK: state
    fileprivate static var container: [RootModel.ID: RootModel] = [:]
    fileprivate static func register(_ object: RootModel) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: RootModel.ID) {
        container[id] = nil
    }
}
