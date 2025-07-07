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
    init() {
        SystemBoardManager.register(self)
    }
    func delete() {
        SystemBoardManager.unregister(self.id)
    }
    
    // MARK: state
    nonisolated let id = ID()
    
    public internal(set) var systemModels: Set<SystemModel.ID> = []
    public var isModelsEmpty: Bool {
        systemModels.isEmpty
    }
    
    public var issue: (any Issuable)?
    public var callback: Callback?
    
    
    
    // MARK: action
    public func createFirstSystem() async {
        await self.createFirstSystem(captureHook: nil)
    }
    func createFirstSystem(captureHook: Hook?) async {
        // capture
        await captureHook?()
        guard id.isExist else { setIssue(Error.systemBoardIsDeleted); return }
        
        // compute
    }
    
    public func subscribe() async {
        await subscribe(captureHook: nil)
    }
    func subscribe(captureHook: Hook?) async {
        
    }
    
    public func unsubscribe() async {
        
    }
    func unsubscribe(captureHook: Hook?) async {
        
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
        case systemBoardIsDeleted
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
