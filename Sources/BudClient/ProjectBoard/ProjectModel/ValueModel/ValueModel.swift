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
        self.description = diff.description
        
        ValueModelManager.register(self)
    }
    func delete() {
        ValueModelManager.unregister(self.id)
    }
    
    
    // MARK: state
    nonisolated let id = ID()
    nonisolated let config: Config<ProjectModel.ID>
    nonisolated let target: ValueID
    nonisolated let updaterRef: Updater
    nonisolated let source: any ValueSourceIdentity
    
    nonisolated let createdAt: Date
    var updatedAt: Date
    var order: Int
    
    public var name: String
    public var description: String?
    
    public var fields: [ValueField] = []

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

