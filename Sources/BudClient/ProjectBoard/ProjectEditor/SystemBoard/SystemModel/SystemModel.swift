//
//  SystemModel.swift
//  BudClient
//
//  Created by 김민우 on 7/5/25.
//
import Foundation
import Values
import BudServer


// MARK: Object
@MainActor @Observable
public final class SystemModel: Sendable, Debuggable, EventDebuggable {
    // MARK: core
    init(config: Config<SystemBoard.ID>,
         target: SystemID,
         sourceLink: SystemSourceLink) {
        self.config = config
        self.target = target
        self.sourceLink = sourceLink
        
        SystemModelManager.register(self)
    }
    func delete() {
        SystemModelManager.unregister(self.id)
    }
    
    // MARK: state
    nonisolated let id = ID()
    nonisolated let config: Config<SystemBoard.ID>
    nonisolated let target: SystemID
    nonisolated let sourceLink: SystemSourceLink
    
    public var location: Location?
    
    public var name: String? // ex) BudClient-iOS, BudClient-MacOS 처럼 시스템의 이름
    
    var updater: SystemUpdater.ID?
    
    public var issue: (any Issuable)?
    package var callback: Callback?
    
    
    // MARK: action
    public func setUp() async {
        await setUp(mutateHook: nil)
    }
    func setUp(mutateHook: Hook?) async {
        // mutate
        await mutateHook?()
        guard id.isExist else { setIssue(Error.systemModelIsDeleted); return }
        guard updater == nil else { setIssue(Error.alreadySetUp); return }
        
        let myconfig = config.setParent(id)
        let systemUpdaterRef = SystemUpdater(config: myconfig)
        self.updater = systemUpdaterRef.id
    }
    
    
    public func subscribe() { }
    public func unsubscribe() { }
    
    
    public func addSystemRight() { }
    public func addSystemLeft() { }
    public func addSystemTop() { }
    public func addSystemBottom() { }
    
    public func createNewObjectModel() { }
    
    public func remove() { }
    
    
    // MARK: value
    @MainActor
    public struct ID: Sendable, Hashable {
        let value: UUID
        nonisolated init(value: UUID = UUID()) {
            self.value = value
        }
        
        var isExist: Bool {
            SystemModelManager.container[self] != nil
        }
        public var ref: SystemModel? {
            SystemModelManager.container[self]
        }
    }
    public enum Error: String, Swift.Error {
        case systemModelIsDeleted
        case alreadySetUp
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
