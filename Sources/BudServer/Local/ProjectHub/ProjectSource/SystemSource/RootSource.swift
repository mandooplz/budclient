//
//  RootSource.swift
//  BudClient
//
//  Created by 김민우 on 7/9/25.
//
import Foundation
import Values
import FirebaseFirestore


// MARK: Object
@MainActor
package final class RootSource: RootSourceInterface {
    // MARK: core
    init(id: ID) {
        self.id = id
        
        RootSourceManager.register(self)
    }
    func delete() {
        RootSourceManager.unregister(self.id)
    }
    
    
    // MARK: state
    package nonisolated let id: ID
    
    
    // MARK: action
    
    
    // MARK: value
    @MainActor
    package struct ID: RootSourceIdentity {
        let value: String
        nonisolated init(_ value: String) {
            self.value = value
        }
        
        package var isExist: Bool {
            RootSourceManager.container[self] != nil
        }
        package var ref: RootSource? {
            RootSourceManager.container[self]
        }
    }
}


// MARK: ObjectManager
@MainActor
fileprivate final class RootSourceManager: Sendable {
    // MARK: state
    fileprivate static var container: [RootSource.ID: RootSource] = [:]
    fileprivate static func register(_ object: RootSource) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: RootSource.ID) {
        container[id] = nil
    }
}

