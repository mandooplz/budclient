//
//  SystemSourceMock.swift
//  BudClient
//
//  Created by 김민우 on 7/8/25.
//
import Foundation
import Values


// MARK: Object
@Server
package final class SystemSourceMock: Sendable {
    // MARK: core
    init(location: Location,
         name: String,
         target: SystemID = SystemID()) {
        self.location = location
        self.name = name
        self.target = target
    }
    
    
    // MARK: state
    nonisolated let id = SystemSourceID()
    nonisolated let target: SystemID
    
    package var location: Location
    package var name: String
    
    
    // MARK: action
}


// MARK: Object Manager
@Server
package final class SystemSourceManager: Sendable {
    // MARK: state
    private static var container: [SystemSourceID: SystemSourceMock] = [:]
    fileprivate static func register(_ object: SystemSourceMock) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: SystemSourceID) {
        container[id] = nil
    }
    package static func get(_ id: SystemSourceID) -> SystemSourceMock? {
        container[id]
    }
    package static func isExist(_ id: SystemSourceID) -> Bool {
        container[id] != nil
    }
}
