//
//  SystemBoard.swift
//  BudClient
//
//  Created by 김민우 on 7/6/25.
//
import Foundation
import Values



// MARK: Object
@MainActor @Observable
public final class SystemBoard: Sendable, Debuggable, EventDebuggable {
    // MARK: core
    init(config: Config<ProjectEditor.ID>) {
        self.config = config
        
        SystemBoardManager.register(self)
    }
    func delete() {
        SystemBoardManager.unregister(self.id)
    }
    
    // MARK: state
    nonisolated let id = ID()
    nonisolated let config: Config<ProjectEditor.ID>
    
    public internal(set) var models: Set<SystemModel.ID> = []
    public var isModelsEmpty: Bool {
        models.isEmpty
    }
    func isExist(_ target: SystemID) -> Bool {
        self.models.lazy
            .compactMap { $0.ref }
            .contains { $0.target == target }
    }
    
    
    public var issue: (any Issuable)?
    public var callback: Callback?
    
    
    // MARK: action
    public func setUp() async {
        await setUp(mutateHook: nil)
    }
    func setUp(mutateHook: Hook?) async {
        // mutate
        await mutateHook?()
        guard id.isExist else { setIssue(Error.systemBoardIsDeleted); return }
    }
    
    public func subscribe() async {
        await self.subscribe(captureHook: nil)
    }
    func subscribe(captureHook: Hook?) async {
        // capture
        await captureHook?()
        guard id.isExist else { setIssue(Error.systemBoardIsDeleted); return }
    }
    
    public func unsubscribe() async {
        await self.unsubscribe(captureHook: nil)
    }
    func unsubscribe(captureHook:Hook?) async {
        // capture
        await captureHook?()
        guard id.isExist else { setIssue(Error.systemBoardIsDeleted); return }
        
    }
    
    public func createFirstSystem() async {
        await self.createFirstSystem(captureHook: nil)
    }
    func createFirstSystem(captureHook: Hook?) async {
        // capture
        await captureHook?()
        guard id.isExist else { setIssue(Error.systemBoardIsDeleted); return }
        guard models.isEmpty else { setIssue(Error.systemAlreadyExist); return }
        let project = config.parent
        let projectSourceLink = project.ref!.sourceLink
        
        // compute
        do {
            try await withThrowingDiscardingTaskGroup { group in
                group.addTask {
                    try await projectSourceLink.createFirstSystem()
                }
            }
        } catch {
            setUnknownIssue(error); return
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
            SystemBoardManager.container[self] != nil
        }
        public var ref: SystemBoard? {
            SystemBoardManager.container[self]
        }
    }
    public enum Error: String, Swift.Error {
        case alreadySetUp
        case systemBoardIsDeleted
        case systemAlreadyExist
    }
}

// MARK: Object Manager
@MainActor @Observable
fileprivate final class SystemBoardManager: Sendable {
    // MARK: state
    fileprivate static var container: [SystemBoard.ID: SystemBoard] = [:]
    fileprivate static func register(_ object: SystemBoard) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: SystemBoard.ID) {
        container[id] = nil
    }
}
