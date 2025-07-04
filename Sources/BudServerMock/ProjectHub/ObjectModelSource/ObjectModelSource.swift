//
//  ObjectModelSource.swift
//  BudClient
//
//  Created by 김민우 on 7/4/25.
//
import Foundation
import Tools


// MARK: Object
@Server
final class ObjectModelSource: Sendable {
    // MARK: core
    init() {
        ObjectModelSourceManager.register(self)
    }
    
    
    // MARK: state
    nonisolated let id = ID()
    
    
    // MARK: action
    
    
    // MARK: value
    @Server
    struct ID: Sendable, Hashable {
        let value: UUID
        nonisolated init(value: UUID = UUID()) {
            self.value = value
        }
        
        var isExist: Bool {
            ObjectModelSourceManager.container[self] != nil
        }
        var ref: ObjectModelSource? {
            ObjectModelSourceManager.container[self]
        }
    }
}


// MARK: Object Manager
@Server
fileprivate final class ObjectModelSourceManager: Sendable {
    fileprivate static var container: [ObjectModelSource.ID : ObjectModelSource] = [:]
    fileprivate static func register(_ object: ObjectModelSource) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: ObjectModelSource.ID) {
        container[id] = nil
    }
}
