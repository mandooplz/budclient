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
final class ObjectModelSource: ServerObject {
    // MARK: core
    init() {
        ObjectModelSourceManager.register(self)
    }
    
    
    // MARK: state
    nonisolated let id = ID()
    
    
    // MARK: action
    
    
    // MARK: value
    @Server
    struct ID: ServerObjectID {
        let value: UUID
        nonisolated init(value: UUID = UUID()) {
            self.value = value
        }
        typealias Object = ObjectModelSource
        typealias Manager = ObjectModelSourceManager
    }
}


// MARK: Object Manager
@Server
final class ObjectModelSourceManager: ServerObjectManager {
    static var container: [ObjectModelSource.ID : ObjectModelSource] = [:]
}
