//
//  ActionModel.swift
//  BudClient
//
//  Created by 김민우 on 7/7/25.
//
import Foundation
import Values
import BudServer

private let logger = BudLogger("ActionModel")


// MARK: Object
@MainActor @Observable
public final class ActionModel: Debuggable, EventDebuggable, Hookable {
    // MARK: core
    init(config: Config<ObjectModel.ID>,
         diff: ActionSourceDiff) {
        self.config = config
        self.target = diff.target
        
        self.name = diff.name
        self.nameInput = diff.name
        
        ActionModelManager.register(self)
    }
    func delete() {
        ActionModelManager.unregister(self.id)
    }
    
    
    // MARK: state
    nonisolated let id = ID()
    nonisolated let config: Config<ObjectModel.ID>
    nonisolated let target: ActionID
    
    public internal(set) var name: String
    public var nameInput: String
    
    public var issue: (any IssueRepresentable)?
    package var callback: Callback?
    
    package var captureHook: Hook?
    package var computeHook: Hook?
    package var mutateHook: Hook?
    
    
    // MARK: action
    public func startUpdating() async {
        logger.start()
        
        // capture
        await captureHook?()
        guard id.isExist else {
            setIssue(Error.actionModelIsDeleted)
            logger.failure("ActionModel이 존재하지 않아 실행 취소됩니다.")
            return
        }
    }
    public func pushName() async {
        logger.start()
        
        // capture
        await captureHook?()
        guard id.isExist else {
            setIssue(Error.actionModelIsDeleted)
            logger.failure("ActionModel이 존재하지 않아 실행 취소됩니다.")
            return
        }
    }
    
    public func duplicateAction() async {
        logger.start()
        
        // capture
        await captureHook?()
        guard id.isExist else {
            setIssue(Error.actionModelIsDeleted)
            logger.failure("ActionModel이 존재하지 않아 실행 취소됩니다.")
            return
        }
    }
    public func removeAction() async {
        logger.start()
        
        // capture
        await captureHook?()
        guard id.isExist else {
            setIssue(Error.actionModelIsDeleted)
            logger.failure("ActionModel이 존재하지 않아 실행 취소됩니다.")
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
            ActionModelManager.container[self] != nil
        }
        public var ref: ActionModel? {
            ActionModelManager.container[self]
        }
    }
    public enum Error: String, Swift.Error {
        case actionModelIsDeleted
        case nameCannotBeEmpty, newNameIsSameAsCurrent
    }
}


// MARK: Object Manager
@MainActor @Observable
fileprivate final class ActionModelManager: Sendable {
    // MARK: state
    fileprivate static var container: [ActionModel.ID: ActionModel] = [:]
    fileprivate static func register(_ object: ActionModel) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: ActionModel.ID) {
        container[id] = nil
    }
}
