//
//  StateModel.swift
//  BudClient
//
//  Created by 김민우 on 7/7/25.
//
import Foundation
import Values
import Collections
import BudServer

private let logger = BudLogger("StateModel")


// MARK: Object
@MainActor @Observable
public final class StateModel: Debuggable, EventDebuggable, Hookable {
    // MARK: core
    init(config: Config<ObjectModel.ID>,
         diff: StateSourceDiff) {
        self.target = diff.target
        self.updaterRef = Updater(owner: self.id)
        self.source = diff.id
        
        self.name = diff.name
        self.nameInput = diff.name
        
        StateModelManager.register(self)
    }
    func delete() {
        StateModelManager.unregister(self.id)
    }
    
    
    // MARK: state
    nonisolated let id = ID()
    nonisolated let target: StateID
    nonisolated let source: any StateSourceIdentity
    nonisolated let updaterRef: Updater
    var isUpdating: Bool = false
    
    public internal(set) var name: String
    public var nameInput: String
    
    public var accessLevel : AccessLevel = .readAndWrite
    public var stateValue: StateValue = .AnyValue 
    
    public internal(set) var getters = OrderedDictionary<GetterID,GetterModel.ID>()
    public internal(set) var setters = OrderedDictionary<SetterID, SetterModel.ID>()
    
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
            setIssue(Error.stateModelIsDeleted)
            logger.failure("StateModel이 존재하지 않아 실행 취소됩니다.")
            return
        }
    }
    
    public func pushName() async {
        logger.start()
        
        // capture
        await captureHook?()
        guard id.isExist else {
            setIssue(Error.stateModelIsDeleted)
            logger.failure("StateModel이 존재하지 않아 실행 취소됩니다.")
            return
        }
    }

    public func appendNewGetter() async {
        logger.start()
        
        // capture
        await captureHook?()
        guard id.isExist else {
            setIssue(Error.stateModelIsDeleted)
            logger.failure("StateModel이 존재하지 않아 실행 취소됩니다.")
            return
        }
    }
    public func appendNewSetter() async {
        logger.start()
        
        // capture
        await captureHook?()
        guard id.isExist else {
            setIssue(Error.stateModelIsDeleted)
            logger.failure("StateModel이 존재하지 않아 실행 취소됩니다.")
            return
        }
    }
    
    public func duplicate() async { }
    
    public func removeState() async {
        
    }
    
    
    // MARK: value
    @MainActor
    public struct ID: Sendable, Hashable {
        public let value: UUID
        nonisolated init(value: UUID = UUID()) {
            self.value = value
        }
        
        public var isExist: Bool {
            StateModelManager.container[self] != nil
        }
        public var ref: StateModel? {
            StateModelManager.container[self]
        }
    }
    public enum Error: String, Swift.Error {
        case stateModelIsDeleted
    }
}


// MARK: Objec Manager
@MainActor @Observable
fileprivate final class StateModelManager: Sendable {
    // MARK: state
    fileprivate static var container: [StateModel.ID: StateModel] = [:]
    fileprivate static func register(_ object: StateModel) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: StateModel.ID) {
        container[id] = nil
    }
}
