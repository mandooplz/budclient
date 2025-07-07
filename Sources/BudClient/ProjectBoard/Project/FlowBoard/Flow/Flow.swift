//
//  Flow.swift
//  BudClient
//
//  Created by 김민우 on 7/4/25.
//
import Foundation
import Values


// MARK: Object
@MainActor @Observable
public final class Flow: Sendable {
    // MARK: core
    init() {
        FlowManager.register(self)
    }
    func delete() {
        FlowManager.unregister(self.id)
    }
    
    // MARK: state
    nonisolated let id = ID()
    
    
    // MARK: action
    
    
    // MARK: value
    @MainActor
    public struct ID: Sendable, Hashable {
        let value: UUID
        nonisolated init(value: UUID = UUID()) {
            self.value = value
        }
        
        var isExist: Bool {
            FlowManager.container[self] != nil
        }
        public var ref: Flow? {
            FlowManager.container[self]
        }
    }
}

// MARK: Flow Manager
@MainActor @Observable
fileprivate final class FlowManager: Sendable {
    fileprivate static var container: [Flow.ID: Flow] = [:]
    fileprivate static func register(_ object: Flow) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: Flow.ID) {
        container[id] = nil
    }
}
