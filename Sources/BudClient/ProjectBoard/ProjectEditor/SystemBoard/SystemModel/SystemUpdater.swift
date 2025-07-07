//
//  SystemUpdater.swift
//  BudClient
//
//  Created by 김민우 on 7/8/25.
//
import Foundation
import Values
import Collections


// MARK: Object
@MainActor @Observable
public final class SystemUpdater: Sendable, Debuggable {
    // MARK: core
    init(config: Config<SystemModel.ID>) {
        self.config = config
        
        SystemUpdaterManager.register(self)
    }
    func delete() {
        SystemUpdaterManager.unregister(self.id)
    }
    
    // MARK: state
    nonisolated let id = ID()
    nonisolated let config: Config<SystemModel.ID>
    
    var queue: Deque<SystemSourceEvent> = []
    
    public var issue: (any Issuable)?
    
    
    // MARK: action
    func update() async {
        await update(mutateHook: nil)
    }
    func update(mutateHook: Hook?) async {
        // mutate
        await mutateHook?()
        guard id.isExist else { setIssue(Error.updaterIsDeleted); return }
        
        while queue.isEmpty == false {
            let event = queue.removeFirst()
            
            // event를 처리
        }
    }
    
    
    // MARK: value
    @MainActor
    struct ID: Sendable, Hashable {
        let value: UUID
        nonisolated init(value: UUID = UUID()) {
            self.value = value
        }
        
        var isExist: Bool {
            SystemUpdaterManager.container[self] != nil
        }
        var ref: SystemUpdater? {
            SystemUpdaterManager.container[self]
        }
    }
    public enum Error: String, Swift.Error {
        case updaterIsDeleted
    }
}



// MARK: Object Manager
@MainActor @Observable
fileprivate final class SystemUpdaterManager: Sendable {
    // MARK: state
    fileprivate static var container: [SystemUpdater.ID: SystemUpdater] = [:]
    fileprivate static func register(_ object: SystemUpdater) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: SystemUpdater.ID) {
        container[id] = nil
    }
}
