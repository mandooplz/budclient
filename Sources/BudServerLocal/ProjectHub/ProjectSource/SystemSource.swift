//
//  SystemSource.swift
//  BudClient
//
//  Created by 김민우 on 7/7/25.
//
import Foundation
import FirebaseFirestore
import Values


// MARK: Object
@MainActor
package final class SystemSource: Sendable {
    // MARK: core
    init(id: SystemSourceID, target: SystemID) {
        self.id = id
        self.target = target
        
        SystemSourceManager.register(self)
    }
    func delete() {
        SystemSourceManager.unregister(self.id)
    }
    
    
    // MARK: state
    nonisolated let id: SystemSourceID
    nonisolated let target: SystemID
    
    
    
    // MARK: action
    
    
    
    // MARK: value
    package struct Data: Hashable, Codable {
        @DocumentID var id: String?
        var target: SystemID
        var name: String
        var location: Location
        var rootModel: Root? // 여기서 Root에 대해 설명할 필요가 있을까. 
        
        package struct Root: Hashable, Codable {
            let target: ObjectID
            let name: String
            let states: [StateID]
            let actions: [ActionID]
        }
    }
    package enum State: Sendable, Hashable {
        static let name = "name"
        static let location = "location"
    }
}


// MARK: Object Manager
@MainActor
package final class SystemSourceManager: Sendable {
    // MARK: state
    package static var container: [SystemSourceID: SystemSource] = [:]
    package static func register(_ object: SystemSource) {
        container[object.id] = object
    }
    package static func unregister(_ id: SystemSourceID) {
        container[id] = nil
    }
    package static func get(_ id: SystemSourceID) -> SystemSource? {
        container[id]
    }
}
